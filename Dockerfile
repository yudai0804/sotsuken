FROM debian:12
WORKDIR /app

RUN apt-get update && apt-get install -y curl octave octave-signal python3 python3-pip iverilog
# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:$PATH"
