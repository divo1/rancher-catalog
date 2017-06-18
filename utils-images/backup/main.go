package main

import (
	"os"
	"fmt"
	"encoding/json"
	"strings"
	"errors"
	"io/ioutil"
	"time"
	"bytes"
	"crypto/md5"
	"encoding/hex"

	"github.com/docker/docker/client"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
	"golang.org/x/net/context"
)

const (
	ImageName = "ubuntu"
)

type Mount struct {
	Src  string
	Dest string
}

type Config struct {
	Name string
	Mount []Mount
}

type Backup struct {
	Configs []Config
}

type BackupConfig struct {
	ContainerName string
	Mount Mount
	Client *client.Client
}

var ctx = context.Background()
func getContext() context.Context {
	return ctx
}

func getConfig(backup Backup, container types.Container) (Config, error) {
	for _, config := range backup.Configs {
		if strings.Contains(container.Names[0], config.Name) {
			return config, nil
		}
	}

	return Config{}, errors.New("Nie znaleziono config'a")
}

func GetMD5Hash(text string) string {
    hasher := md5.New()
    hasher.Write([]byte(text))
    return hex.EncodeToString(hasher.Sum(nil))
}

func initConfig(config BackupConfig) (*container.Config) {
	t := time.Now()
	backupDir := "/backup/" + strings.Replace(config.ContainerName, "\\", "-", -1) + "/" + GetMD5Hash(config.Mount.Src) + "/"
	dir := backupDir + t.Format("2006/01/02/15/")
	ext := ".tar"

	var backupFileName bytes.Buffer
	backupFileName.WriteString(dir)
	backupFileName.WriteString(t.Format("04.05.999999"))
	backupFileName.WriteString(ext)

	fmt.Println("Backup file name: " + backupFileName.String())

	var commandBuf bytes.Buffer
	commandBuf.WriteString("mkdir -p " + dir)
	commandBuf.WriteString(" && tar cvf " + backupFileName.String() + " " + config.Mount.Src)
	commandBuf.WriteString(" && rm -f " + backupDir + "latest" + ext)
	commandBuf.WriteString(" && ln -s " + backupFileName.String() + " " + backupDir + "latest" + ext)

	fmt.Println(commandBuf.String())
	return &container.Config{Image: ImageName, Cmd: []string{"sh", "-c", commandBuf.String()}}
}

func createContainer(config BackupConfig) (container.ContainerCreateCreatedBody, error) {
	return config.Client.ContainerCreate(getContext(), initConfig(config), &container.HostConfig{Binds: []string{config.Mount.Dest + ":/backup"}, AutoRemove: true, VolumesFrom: []string{config.ContainerName}}, nil, "")
}

func getFile(fileName string) []byte {
	file, e := ioutil.ReadFile(fileName)
	if e != nil {
		fmt.Printf("File error: %v\n", e)
		os.Exit(1)
	}

	//fmt.Printf("%s\n", string(file))
	return file
}

func getBackup(file []byte) Backup {
	var backup Backup
	json.Unmarshal(file, &backup)

	return backup
}

func getDockerClient() *client.Client {
	client, err := client.NewClient("unix:///var/run/docker.sock", "1.24", nil, nil)
	if err != nil {
		panic(err)
	}

	return client
}

func backupContainer(config BackupConfig) {
	ctnr, e := createContainer(config)
	if e != nil {
		fmt.Printf("File error: %v\n", e)
		return
	}

	fmt.Printf("Backup: %+v\n", config)
	fmt.Printf("Ctnr: %+v\n", ctnr)
	if err := config.Client.ContainerStart(getContext(), ctnr.ID, types.ContainerStartOptions{}); err != nil {
		panic(err)
	}
}

func getDockerContainers(client *client.Client) []types.Container {
	containers, err := client.ContainerList(getContext(), types.ContainerListOptions{})
	if err != nil {
		panic(err)
	}

	return containers
}

func main() {
	os.Setenv("DOCKER_API_VERSION", "1.24")
	CONFIG_FILE := "./config.json"
	file := getFile(CONFIG_FILE)
	backup := getBackup(file)
	client := getDockerClient()
	containers := getDockerContainers(client)

	for _, container := range containers {
		//fmt.Printf("Image: %+v\n", container)

		config, e := getConfig(backup, container)
		if e != nil {
			continue
		}

		for _, mount := range config.Mount {
			backupContainer(BackupConfig{Client: client, ContainerName: config.Name, Mount: Mount{Src: mount.Src, Dest: mount.Dest}})
		}
	}
}