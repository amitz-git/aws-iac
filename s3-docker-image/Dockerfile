FROM ubuntu
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=IST
RUN apt-get update
RUN apt-get install -y
RUN apt-get install awscli -y

ENV AWS_ACCESS_ID=
ENV AWS_SECRES_ACCESS_KEY=
ENV AWS_REGION=ap-south-1

CMD aws s3api create-bucket --bucket bucket-from-docker --create-bucket-configuration LocationConstraint=$AWS_REGION
