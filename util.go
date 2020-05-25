package main

import (
	"bytes"
	"sort"
	"strings"
)

func ParseAppConfig(s string) AppConfig {
	parts := strings.Split(s, ",")

	c := AppConfig{}

	for i := range parts {
		kv := strings.Split(parts[i], "=")

		if kv[0] == "" {
			continue
		}

		if len(kv) == 2 {
			c[kv[0]] = kv[1]
		} else {
			c[kv[0]] = ""
		}
	}

	return c
}

type AppConfig map[string]string

func (c AppConfig) String() string {
	keys := make([]string, 0)

	for k := range c {
		keys = append(keys, k)
	}

	sort.Strings(keys)

	buf := bytes.NewBuffer(nil)

	for i, k := range keys {
		if i != 0 {
			buf.WriteByte(',')
		}
		buf.WriteString(k)
		buf.WriteByte('=')
		buf.WriteString(c[k])
	}

	return buf.String()
}
