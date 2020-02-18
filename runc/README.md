### Instructions to run containers using runC

1. Create a new directory for the container
`mdkir ./my-container && cd my-container`

2. Create a root filesystem
`mkdir rootfs`

3. Export the docker image into the root filesystem
`docker export $(docker create <image-tag>) | tar -C rootfs -xvf -`

4. Create a spec file
`runc spec`

5. To run rootless containers we must modify a flag in the kernel:
`cat /proc/sys/kernel/unprivileged_userns_clone`
must be set to 1.
```
su -
echo 1 > /proc/sys/kernel/unprivileged_userns_clone
exit
```

6. To set up a network namespace we use [netns](https://github.com/genuinetools/netns)

### Specific Examples

1. [Redis Server](https://github.com/BU-NU-CLOUD-F19/Interoperable_Container_Runtime/wiki/Configuring-network-with-runc:-redis-container)
    i. 	  cd ~/criu-demos/runc/redis && sudo runc run -d eureka &> /dev/null < /dev/null
    ii.   sudo netns ls
    iii.  redis-cli -h <IP>
    iv.   redis> SET mykey "hello"
    v.    sudo runc checkpoint eureka
    // observe that the container has disappeared, (not stopped) hence allowing for transparent migration
    // rather than havng to deal with container names around (docker)
    vi.   sudo runc restore -d eureka &> /dev/null < /dev/null
    vii.  redis-cli -h <IP> // note that it is a new one
    viii. GET mykey
