# Firt Docker Container

During this lab, you will use basic docker commands to get familiar with docker CLI and concepts.
The challenge for you is to run [Alpine Linux](http://www.alpinelinux.org/), which is a lightweigth linux distribution.
After that, you will build your first docker image and run your container locally.

## Specific instruction

If you are using lab 15 to perform the instructions from a lab VM, you will have to first update Docker.
Right click on docker icone in the task bar and select **Update and Restart**

## Instructions

### Run Alpine Linux

To get started, run the following in your terminal:
```
docker pull alpine
```

The `pull` command download the alpine **image** from the **Docker Hub Registry** and saves it on your local machine. As you did not specify a version, it will take the image with the tag `latest`, but you can also specify the registry and/or the version you want:
```
docker pull alpine:3.11.11
```

You can run an image even if you don't pull it first, as Docker will pull it for you when you execute the run command.
You can use the `docker images` command to see a list of all images on your system.

```
docker images
REPOSITORY              TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
alpine                  latest              6dbb9cc54074        5 weeks ago         5.61 MB
```

Now, let's run a Docker conainter based on this image. You are going to use the `docker run` command.
```
$ docker run alpine ls -l
total 56
drwxr-xr-x    2 root     root          4096 Oct 25 22:05 bin
drwxr-xr-x    5 root     root           340 Nov  7 07:09 dev
......
```

As you see, when you called the command `run`, the Docker client finds the image (locally, because you pulled it first), creates the container and then runs a command in that (here, the command is `ls - l` which list the content of the current directory) container.

Now, you can try other commands:
 - Try and print 'Hello World' in the output while using docker run alpine command.
 (Hint: to print something on  linux, use the `echo` command)
 - You can also try opening a shell within the container and execute multiple commands interactively
 (Hint: the shell is /bin/sh on Alpine, and you can find docummentation on the run command here: https://docs.docker.com/engine/reference/run/#foreground)

Finally, you can run the container in detached mode so it keep running by itself usin the `-d` flag on the run command.
```
docker run -d alpine
```
And now, you can see all your running container using `docker ps`:
```
docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

Wait, there is only a blank line. Where is my container? By default, docker ps only show running containers, and Alpine image, by itself, is not a long running container so as soon as the default comand is executed, it stops. To see all your containers, you should use the `--all/-a` flag:
```
docker ps -a
CONTAINER ID        IMAGE                                 COMMAND                  CREATED              STATUS                          PORTS               NAMES
e31379b50e42        alpine                                "/bin/sh"                18 seconds ago       Exited (127) 9 seconds ago                          priceless_rhodes
6a159363e10d        alpine                                "/bin/sh"                About a minute ago   Exited (0) About a minute ago                       happy_knuth
```

If your container is still running and you want to stop it, you should use the `docker stop` command with your container id as a parameter. Afterward, to delete your container, use the command  `docker stop` command with your container id as a parameter:
```
docker rm e31379b50e42
```

### Your First Image

Now that you understand how to run a container, let's build our own container to host a simple python website.
First, create a new directory for your application
```
mkdir myapp
cd myappd
```

Then, you will create our application. Create a file named **app.py** with the content:
```
from flask import Flask, render_template
import random

app = Flask(__name__)

# list of images
images = [
    "https://i2.wp.com/dianaurban.com/wp-content/uploads/2017/07/01-cat-stretching-feet.gif",
    "https://static.wixstatic.com/media/4cbe8d_f1ed2800a49649848102c68fc5a66e53~mv2.gif"
]

@app.route('/')
def index():
    url = random.choice(images)
    return render_template('index.html', url=url)

if __name__ == "__main__":
    app.run(host="0.0.0.0")
```

Then, to manage python packages for ou application, you will use a **requirements.txt** file which will contain:
```
Flask==0.10.1
```

Then you create our **index.html** page that will be displayed:
```
<html>
  <head>
    <style type="text/css">
      body {
        background: white;
        color: black;
      }
      div.container {
        max-width: 500px;
        margin: 100px auto;
        border: 20px solid white;
        padding: 10px;
        text-align: center;
      }
      h4 {
        text-transform: uppercase;
      }
    </style>
  </head>
  <body>
    <div class="container">
      <h4>Cat Gif</h4>
      <img src="{{url}}" />
    </div>
  </body>
</html>
```

Now that our app is ready, you need to create the Dockerfile that will be use to generate the image.
First step is, create a file called **Dockerfile** (with no extension).
Then, you will first start from the latest alpine image
```
FROM alpine:latest
```

Usually, you follow up by using a command to install required dependencies. You will start by installing pip, which is a package manager for python
```
RUN apk add --update py-pip
```

Next, using pip, you will install python dependencies. You first copy the requirement file into the image, then you use it to install the package:
```
COPY requirements.txt /usr/src/app/
RUN pip install --no-cache-dir -r /usr/src/app/requirements.txt
```

After that, you can deploy your website within the image by coping the required files
```
COPY app.py /usr/src/app/
COPY index.html /usr/src/app/templates/
```

Then, we will tell docker which port will be exposed by the image. Flask is running on 5000, so we expose port 5000.
```
EXPOSE 5000
```

Finally, you will tell docker which command should be executed when you run the image. We want to start our application using pythion command line:
```
CMD ["python3", "/usr/src/app/app.py"]
```

The final result is:
```
# our base image
FROM alpine:latest

# Install python and pip
RUN apk add --update py-pip

# install Python modules needed by the Python app
COPY requirements.txt /usr/src/app/
RUN pip install --no-cache-dir -r /usr/src/app/requirements.txt

# copy files required for the app to run
COPY app.py /usr/src/app/
COPY index.html /usr/src/app/templates/

# tell the port number the container should expose
EXPOSE 5000

# run the application
CMD ["python3", "/usr/src/app/app.py"]
```

You now have a Dockerfile! but you still need to build it to have your image. This is the step where your Dockerfile will be processed by docker and an image will be created that you can use later on.
```
docker build -t myfirstapp .
```

the flag `-t` is to add a tag to the image, like a name, that we can use later on to run the image.
In the console, you should see all the steps described in your Dockerfile happening one by one.
When your image is built, use the `docker images` command to validate that it is avaiable.

The final step will be to run the image and test your website. DOn't forget to use `-p` flag to bridge the port of your host with the one from your container.
The command should be:
```
docker run -p 8080:5000 myfirstapp
```

If you open your web browser and navigate to http://127.0.0.1:8080/ you should see your website! 

When you are done, don't forget to stop the container and to remove it.
