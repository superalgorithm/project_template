# Use an official Python runtime as a parent image
FROM python:3.12-slim

# Set the working directory
WORKDIR /app

# Copy the common code into the image
COPY . /app/common
COPY csv_data /app/csv_data

RUN pip install --no-cache-dir -r common/requirements.txt

# Define an environment variable for other modules to find common code
ENV PYTHONPATH="/app:/app/common"


RUN pytest /app/common/tests