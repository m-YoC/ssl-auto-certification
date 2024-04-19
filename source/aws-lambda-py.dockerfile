FROM public.ecr.aws/r8e9h4b2/lambda/python-with-awscli:3.12
# FROM public.ecr.aws/r8e9h4b2/lambda/python-with-awscli:3.12v2

# RUN pip install --upgrade pip
RUN pip install certbot certbot-dns-route53
RUN dnf update && dnf install -y augeas-libs

COPY main.py ${LAMBDA_TASK_ROOT}

CMD ["main.handler"]
