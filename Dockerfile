FROM python:3.6-stretch

#Install git
RUN apt-get update && apt-get install -y git

#Install the django hello-world requirements
RUN apt-get install python3-dev python3-pip python3-virtualenv sqlitebrowser

# Add requirements file used by pip install
ADD ./requirements.txt /how_to_CI_CD/
WORKDIR /how_to_CI_CD

# Run pip install to install all python dependenies
RUN pip3 install --no-cache-dir -r requirements.txt

# Add all the project files
ADD . /how_to_CI_CD

EXPOSE 8000
