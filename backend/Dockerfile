FROM python:3.10-buster

# Install system dependencies
RUN apt-get update && \
    apt-get install -y build-essential default-libmysqlclient-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the requirements and install them
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy the project code
COPY . .

# Expose the application port
EXPOSE 8000

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# CMD that will start the server (this gets passed to exec in the entrypoint script)
CMD ["python3", "manage.py", "runserver", "0.0.0.0:8000"]

