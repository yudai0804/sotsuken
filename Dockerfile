FROM debian12
WORKDIR /app

RUN apt-get update && apt-get install -y octave octave-signal python3 python3-pip
# Install Poetry
curl -sSL https://install.python-poetry.org | python3 -