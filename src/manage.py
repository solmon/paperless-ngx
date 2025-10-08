#!/usr/bin/env python3
import os
import sys

os.environ["CURL_CA_BUNDLE"] = "/home/solmon/github/questmind/zscaler_root.crt"
os.environ["REQUESTS_CA_BUNDLE"] = "/home/solmon/github/questmind/zscaler_root.crt"
os.environ["GRPC_DEFAULT_SSL_ROOTS_FILE_PATH"] = "/home/solmon/github/questmind/zscaler_root.crt"

if __name__ == "__main__":
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "paperless.settings")

    from django.core.management import execute_from_command_line

    execute_from_command_line(sys.argv)
