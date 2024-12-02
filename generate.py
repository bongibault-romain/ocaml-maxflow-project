import random
import string
import os

# generate a file like this:
#
# 0 1 2 3 4 5 6 7 8 9 0 19 28 4 
#
# 0 1 2 3 4 5 91 
# 1 0 8 1 3 8 4
# 2 1 9 2 3 9 4
# 3 1 0 3 4 0 5
# 4 1 1 4 5 1 6

# the first line has all the numbers from 0 to 1000

def generate_first_line(n):
    return " ".join(str(i) for i in range(n))

def generate_line(i, n, wishes=10):
    generated_wishes = []

    for _ in range(wishes):
        num = random.randint(0, n-1)
        while num in generated_wishes:
            num = random.randint(0, n-1)
        generated_wishes.append(num)

    return str(i) + " " + " ".join(str(num) for num in generated_wishes)

def generate_lines(n, wishes=10):
    return "\n".join(generate_line(i, n, wishes) for i in range(n))

def generate_file(n, wishes=10):
    with open("wishes/wish_4.txt", "w") as f:
        f.write(generate_first_line(n) + "\n")
        f.write(generate_lines(n, wishes))

generate_file(1000, 6)