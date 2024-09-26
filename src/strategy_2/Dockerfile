# Base image
FROM common_code_image:latest

# Set the working directory
WORKDIR /app

# Copy the current folder contents into the container at /app
COPY . /app

# Copy the parent 'common' folder into the container at /app/common
# COPY common /app/common

# Set the PYTHONPATH to include both /app and /app/common
# ENV PYTHONPATH="/app:/app/common"

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Command to run the application
CMD ["python", "-u", "./main.py"]
