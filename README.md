# go-grpc-minimal-server
A minimalistic gRPC server written in Go to be used when debugging connections.

The intention for this project is to provide a super simple server application
that can produce "proper" responses to help you debug any weird
network/proxy/firewall issues by removing as much superfluous stuff as possible.
This is not a guide of how to learn gRPC, and most of this code is more or less
ripped from either one of these locations:

- [x-team.com](https://x-team.com/blog/golang-rpc-twirp/)
- [sahansera.dev](https://sahansera.dev/building-grpc-server-go/)
- [grpc.io](https://grpc.io/docs/languages/go/quickstart/)
- [tutorialedge.net](https://tutorialedge.net/golang/go-grpc-beginners-tutorial/)

so I would recommend going to those places for more in depth knowledge.

## Build
With the help of the Makefile this project should be as easy as this to build:

> NOTE: The build commands make use of [Docker][1] to reduce the need of
> installing the protoc packages on the host machine, so that is a prerequisite.

```
make build
```

This should then produce a binary file called `simple-grpc-server`.

If you want to create a Docker image that includes this binary you can just
run:

```
make docker-build
```

This then produce a local image named `grpc-minimal-server:latest`.

## Run
To start the gRPC server from the binary you can just do this:

```
./simple-grpc-server
```

and it will start listening to port 9000.

If you have built the Docker image you may instead do the following:

```
docker run -it -p 9000:9000 grpc-minimal-server:latest
```

where the first "9000" is the port that is exposed on the host machine.

## How I Use It
When there are network issues you might not always want to pull out the big guns
like [`tcpdump`][2] or [Wireshark][2], but rather just want something quick and
dirty to see if traffic flows at all. With HTTP I usually use [`curl`][4], or
just the browser directly, with one of these "servers" running on the machine
I am trying to reach:

- `nc -l -p 9000`
- `python3 -m http.server 9000 --bind 0.0.0.0`

This shows me what arrives at the host, and if a response is readable by the
browser. But I could not find such a simple solution for gRPC, which is the
reason behind this repo, so here is my workflow:

### Start the Server
SSH to the host machine you are trying to reach and start the minimal gRPC
server with either the binary directly or with the Docker run command explained
[above](#run). Keep the terminal open so you can see any log messages that
are printed.

For the example here I will just start the binary directly on my local machine:

```sh
./simple-grpc-server
```

which now listens for incoming connections on port 9000, and will be reachable
via `localhost:9000`.

### Run gRPC Queries
There is the program [`grpcurl`][5], which is "Like cURL, but for gRPC", that
you can [install][6] in some different ways, but I prefer to use the Docker
image. In the following examples I use `localhost:9000` as the host (since that
is what I started above), but that should be changed to the name of the actual
server in a real situation.

#### Download the Docker Image
```sh
docker pull fullstorydev/grpcurl:latest
```

#### Get Current Amount of Paperclips
```sh
docker run -it --network=host --rm fullstorydev/grpcurl:latest \
    -plaintext localhost:9000 PaperclipCounter/GetPaperclips
```

which should produce a response similar to

```json
{
    "paperclips": 1
}
```


#### Add Paperclips
```sh
docker run -it --network=host --rm fullstorydev/grpcurl:latest \
    -plaintext -d '{"paperclips": 2}' \
    localhost:9000 PaperclipCounter/IncrementPaperclips
```

which should produce an empty response like this

```json
{

}
```

You may then experiment with setting different values in the JSON body provided
after the `-d` parameter and see what happens and what responses you get.

### Note About Responses
Something that might be nice to know when working with `grpcurl` is that
"default" values (like `0`, `""`, `false`) are not printed unless you
provide the `-emit-defaults` flag. So in the case we have `0` paperclips you
would just get an empty JSON struct printed unless you do the following:

```sh
docker run -it --network=host --rm fullstorydev/grpcurl:latest \
    -plaintext -emit-defaults \
    localhost:9000 PaperclipCounter/GetPaperclips
```
```json
{
  "paperclips": 0
}
```

### Note About `-plaintext`
The gRPC protocol use HTTP2 as its transport medium, and while there is nothing
[forbidding][7] HTTP2 from using unencrypted connections it is absolutely very
rare to see it. The unencrypted solution is called HTTP2 Over Cleartext, usually
shortened to `h2c`, and this might not be supported by all clients.

In our case we have implemented the bare minimum on the server, so it only
speaks cleartext, which is why we need to add the `-plaintext` flag when using
the `grpcurl` client. However, this might cause issues for you if you are
trying to place this minimal server behind a reverse proxy that terminates TLS
connections and just forwards the plaintext result afterwards.

In Nginx you can do something [like this][8] to support both cases:

```conf
http {
    server {
        listen 80 http2;
        listen 443 ssl http2;
        location / {
            grpc_pass grpc://localhost:9000;
        }
    }
}
```

while Caddy use the not-officially-supported [h2c][9] package to achieve the
same thing:

```conf
{
    servers {
        protocols h1 h2c h2
    }
}
http://example.com {
    reverse_proxy h2c://localhost:9000
}
example.com {
    reverse_proxy h2c://localhost:9000
}
```






[1]: https://docs.docker.com/engine/install/
[2]: https://www.tcpdump.org/
[3]: https://www.wireshark.org/
[4]: https://curl.se/
[5]: https://github.com/fullstorydev/grpcurl
[6]: https://github.com/fullstorydev/grpcurl#installation
[7]: https://daniel.haxx.se/blog/2015/03/06/tls-in-http2/
[8]: https://www.nginx.com/blog/nginx-1-13-10-grpc/
[9]: https://pkg.go.dev/golang.org/x/net/http2/h2c
