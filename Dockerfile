FROM postgres:18

RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    sudo

# Set up working directory for development
WORKDIR /app/src
COPY src/ /app/src/

# Keep src writable for development
VOLUME /app/src
