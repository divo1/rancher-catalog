package main

import (
	"os"
	"errors"

	"github.com/docker/docker/client"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
	"golang.org/x/net/context"
)

const (
	DOCKER_API_VERSION = "1.24"
	DOCKER_SOCKET = "unix:///var/run/docker.sock"
	DOCKER_IMAGE = "ubuntu"
)

var Context = context.Background()
func getContext() context.Context {
	return Context
}

type Docker struct {
	version string
	socket string
	image string
	client *client.Client
}

type DockerConfig struct {
	cmd string
	VolumesFrom []string
	Binds []string
}

func getDockerClient() (*client.Client) {
	client, err := client.NewClient("unix:///var/run/docker.sock", "1.24", nil, nil)
	if err != nil {
		panic(err)
	}

	return client
}

func isInSlice(haystack []string, needle string) bool {
	for _, h := range haystack {
		if h == needle {
			return true;
		}
	}
	
	return false
}

func NewDocker() (*Docker, error) {
	Info.Print("Creating docker object")
	docker := new(Docker)
	docker.version = DOCKER_API_VERSION
	docker.socket = DOCKER_SOCKET
	docker.image = DOCKER_IMAGE

	Info.Print("Docker api version: ", docker.version)
	os.Setenv("DOCKER_API_VERSION", docker.version)
	
	client, err := client.NewClient(docker.socket, docker.version, nil, nil)
	if err != nil {
		return nil, err
	}
	docker.client = client

	return docker, nil
}

func (d Docker) getRuningContainers() []types.Container {
	containers, err := d.client.ContainerList(getContext(), types.ContainerListOptions{})
	if err != nil {
		panic(err)
	}

	return containers
}

func (d Docker) isFromContainersWithName(containers []types.Container, name string) bool {
	for _, container := range containers {
		Info.Print("Containers - ID: ", container.ID, ", names: ", container.Names, ", searching name: ", name)
		if isInSlice(container.Names, "/" + name) {
			return true
		}
	}
	
	return false
}

func (d Docker) isRuningContainerWithName(name string) bool {
	return d.isFromContainersWithName(d.getRuningContainers(), name)
}

func (d Docker) createNewContainer(config DockerConfig) (container.ContainerCreateCreatedBody, error) {
	cfg := &container.Config{Image: d.image, Cmd: []string{"sh", "-c", config.cmd}}
	hostConfig := &container.HostConfig{Binds: config.Binds, AutoRemove: true, VolumesFrom: config.VolumesFrom}
	return d.client.ContainerCreate(getContext(), cfg, hostConfig, nil, "")
}

func (d Docker) startNewContainer(config DockerConfig) error {
	ctnr, e := d.createNewContainer(config)
	if e != nil {
		Error.Print("Can't create new container: ", config)
		return errors.New("Can't create new container")
	}
	
	if err := d.client.ContainerStart(getContext(), ctnr.ID, types.ContainerStartOptions{}); err != nil {
		Error.Print("Can't start new container: ", config)
		return errors.New("Can't start new container")
	}
	
	return nil
}