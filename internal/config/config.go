package config

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/jessevdk/go-flags"
	"gopkg.in/yaml.v2"
)

type Config struct {
	Home string `env:"HOME"`

	ConfigFilePath string `default:"config.yaml"`

	BaseDomain string `short:"b" long:"base-domain" env:"BASE_DOMAIN" yaml:"base_domain" default"127-0-0-1.nip.io"`

	RepoUrl      string
	Remote       string
	RemoteBranch string
	RemoteUrl    string

	ClusterName  string
	ArtifactsDir string

	Distribution *Distribution

	Version bool
}

type Distribution struct {
	ContainerPlatform string `long:"container-platform" default:"k3s"`
	Flavor            string `long:"flavor" default:"_"`
	Provider          string `long:"provider" default:"docker"`
}

// LoadConfigFromYaml loads the config from config file
func (c *Config) LoadConfigFromYaml() *Config {
	fmt.Printf("Loading config from %s\n", c.ConfigFilePath)
	yamlFile, err := ioutil.ReadFile(c.ConfigFilePath)
	if err != nil {
		log.Printf("yamlFile.Get err #%v ", err)
	}

	err = yaml.Unmarshal(yamlFile, c)
	if err != nil {
		log.Fatalf("Unmarshal err: %v", err)
	}

	return c
}

// LoadConfig loads the config from flags & environment
func LoadConfig(version string) *Config {
	var c Config
	parser := flags.NewParser(&c, flags.Default)
	if _, err := parser.Parse(); err != nil {
		os.Exit(1)
	}

	if c.ConfigFilePath != "" {
		if _, err := os.Stat(c.ConfigFilePath); err == nil {
			c.LoadConfigFromYaml()
		} else {
			fmt.Printf("File %s doesn't exists!\n", c.ConfigFilePath)
			os.Exit(1)
		}
	}

	if c.Version {
		fmt.Printf("DevBootOps v%v\n", version)
		os.Exit(0)
	}

	return &c
}
