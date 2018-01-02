#!/bin/bash

bundle install
PORT=3205 bundle exec foreman start
