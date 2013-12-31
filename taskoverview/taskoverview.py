#!/usr/bin/python


if __name__ == '__main__' and __package__ is None:
	from docopt import docopt
	usage = """Usage: taskoverview.py [-h] PATH

	-h --help  show this help

	"""
	opts = docopt(usage)

	from lib import main
	main(opts)
