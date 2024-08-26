FROM debian:latest
WORKDIR /app

RUN apt-get update && apt-get install -y octave octave-signal python3 python3-pip

WORKDIR /app

COPY ./requirements.txt ./requirements.txt
RUN pip install -r ./requirements.txt --break-system-packages