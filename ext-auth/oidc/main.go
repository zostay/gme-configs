package main

import (
	"os"

	"gopkg.in/yaml.v3"
)

type ClientInfo struct {
	ClientId     string `yaml:"client_id"`
	ClientSecret string `yaml:"client_secret"`

	Login    string `yaml:"login"`
	Password string `yaml:"password"`
}

func main() {
	clientInfo, err := LoadClientInfo()
	if err != nil {
		panic(err)
	}
}

func LoadClientInfo() (*ClientInfo, error) {
	clientInfoBytes, err := os.ReadFile("oidc-client.yaml")
	if err != nil {
		return nil, err
	}

	var clientInfo ClientInfo
	err = yaml.Unmarshal(clientInfoBytes, &clientInfo)

	return &clientInfo, err
}
