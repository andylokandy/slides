docker run --rm -v $PWD:/home/marp/app/ -p 8080:8080 -p 37717:37717 -e MARP_USER="$(id -u):$(id -g)" -e LANG=$LANG marpteam/marp-cli --html --theme light.css -s .
