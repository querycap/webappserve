package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"mime"
	"net/http"
	"os"
	"os/signal"
	"path"
	"strings"
	"syscall"
	"time"

	"github.com/NYTimes/gziphandler"
	"github.com/rs/cors"
	"github.com/spf13/cobra"
)

var serverOpt = &WebappServerOpt{}

var cmd = &cobra.Command{
	Run: func(cmd *cobra.Command, args []string) {
		if err := Serve(serverOpt); err != nil {
			panic(err)
		}
	},
}

func init() {
	cmd.Flags().StringVarP(&serverOpt.Port, "port", "p", os.Getenv("PORT"), "port")
	cmd.Flags().StringVarP(&serverOpt.AppRoot, "root", "", os.Getenv("APP_ROOT"), "app root")
	cmd.Flags().StringVarP(&serverOpt.AppConfig, "config", "c", os.Getenv("APP_CONFIG"), "app config")
	cmd.Flags().StringVarP(&serverOpt.AppEnv, "env", "e", os.Getenv("APP_ENV"), "app env")
}

func main() {
	if err := cmd.Execute(); err != nil {
		panic(err)
	}
}

func Serve(opt *WebappServerOpt) error {
	gzipHandler, err := gziphandler.GzipHandlerWithOpts(gziphandler.ContentTypes([]string{
		"application/json",
		"application/javascript",
		"image/svg+xml",
		"text/html",
		"text/xml",
		"text/plain",
		"text/css",
		"text/*",
	}))
	if err != nil {
		return err
	}

	if opt.Port == "" {
		opt.Port = "80"
	}

	srv := &http.Server{Addr: ":" + opt.Port, Handler: gzipHandler(WebappServer(opt))}

	stopCh := make(chan os.Signal, 1)
	signal.Notify(stopCh, os.Interrupt, syscall.SIGTERM)

	go func() {
		log.Printf("webapp serve on %s\n", srv.Addr)

		if err := srv.ListenAndServe(); err != nil {
			if err == http.ErrServerClosed {
				log.Println(err)
			} else {
				log.Fatalln(err)
			}
		}
	}()

	<-stopCh

	log.Printf("shutdowning in %s\n", 10*time.Second)

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	return srv.Shutdown(ctx)
}

type WebappServerOpt struct {
	AppConfig string
	AppEnv    string
	AppRoot   string
	Port      string
}

func WebappServer(opt *WebappServerOpt) http.Handler {
	indexHTML, err := ioutil.ReadFile(path.Join(opt.AppRoot, "./index.html"))
	if err != nil {
		panic(err)
	}

	appConfig := ParseAppConfig(opt.AppConfig)

	indexHTML = bytes.ReplaceAll(indexHTML, []byte("__ENV__"), []byte(opt.AppEnv))
	indexHTML = bytes.ReplaceAll(indexHTML, []byte("__APP_CONFIG__"), []byte(appConfig.String()))

	cwd, _ := os.Getwd()
	root := path.Join(cwd, opt.AppRoot)

	if len(opt.AppRoot) > 0 && opt.AppRoot[0] == '/' {
		root = opt.AppRoot
	}

	return &webappServer{
		indexHTML:   indexHTML,
		fileHandler: http.FileServer(http.Dir(root)),
		corsHandler: cors.Default(),
		appConfig:   appConfig,
	}
}

type webappServer struct {
	appConfig   AppConfig
	indexHTML   []byte
	corsHandler *cors.Cors
	fileHandler http.Handler
}

func (s *webappServer) responseFromIndexHTML(w http.ResponseWriter) {
	w.Header().Set("Content-Type", mime.TypeByExtension(".html"))

	w.Header().Set("X-Frame-Options", "sameorigin")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("X-XSS-Protection", "1; mode=block")

	w.WriteHeader(http.StatusOK)
	if _, err := io.Copy(w, bytes.NewBuffer(s.indexHTML)); err != nil {
		writeErr(w, http.StatusNotFound, err)
	}
}

func (s *webappServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	p := r.URL.Path

	if p == "/favicon.ico" {
		expires(w.Header(), 24*time.Hour)

		s.fileHandler.ServeHTTP(w, r)
		return
	}

	if p == "/sw.js" {
		s.fileHandler.ServeHTTP(w, r)
		return
	}

	if strings.HasPrefix(p, "/__built__/") {
		if p == "/__built__/config.json" {
			s.corsHandler.HandlerFunc(w, r)
			w.Header().Set("Content-Type", mime.TypeByExtension(".json"))
			w.WriteHeader(http.StatusOK)
			_ = json.NewEncoder(w).Encode(s.appConfig)
			return
		}

		expires(w.Header(), 30*24*time.Hour)

		s.fileHandler.ServeHTTP(w, r)
		return
	}

	s.responseFromIndexHTML(w)
}

func expires(header http.Header, d time.Duration) {
	header.Set("Cache-Control", fmt.Sprintf("max-age=%d", d/time.Second))
}

func writeErr(w http.ResponseWriter, status int, err error) {
	w.WriteHeader(status)
	_, _ = w.Write([]byte(err.Error()))
}
