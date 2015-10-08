#!/bin/bash


yes | ssh-keygen -P '' -f ~/.ssh/id_rsa 2>&1 | tee result.log



