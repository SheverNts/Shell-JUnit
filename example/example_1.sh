#!/bin/bash
source junit.sh

a(){
echo "hello world.."
echo "hello world.."
sleep 1
echo "hello world.."
echo "hello world.."
echo "hello world.."
echo "hello world.."
}

b(){
echo "hello world.."
echo "hello world.."
sleep 2
echo "hello world.."
echo "hello world.."
}

c(){
echo "hello world???"
echo "hello world???"
sleep 3
echo "hello world???"
echo "hello world???"
}

included_spec=( a b c )

MY_JUNIT junit.xml "Infra-Sanity" ${included_spec[*]} 
