#!/usr/bin/env python

import yaml
import sys 
import argparse
import flatten

if __name__ == '__main__':
  parser = argparse.ArgumentParser(description='Load some values from a yaml file.')
  requiredArgs = parser.add_argument_group('required arguments')
  requiredArgs.add_argument("-f", "--file", dest="filename", nargs='?', type=argparse.FileType('r'),
    help="YAML_FILE to read the value from, or '-' if to read from STDIN", required=True, metavar="YAML_FILE|-")
  requiredArgs.add_argument("-k", "--keys", dest="keys", nargs='+',
    help="string to search in dot.notation of snake_case_notation", required=True)
  requiredArgs.add_argument("-v", "--verbose", action="store_true", dest="verbose", default=False,
    help="enable verbose output", required=False)
  requiredArgs.add_argument("-c", "--check", action="store_true", dest="checkExists", default=False,
    help="check if a key or keys exist", required=False)
  args = parser.parse_args()
  inputFile=args.filename
  inputKeys=args.keys

  if inputFile.name == '<stdin>':
    y=yaml.safe_load(sys.stdin.read())
  else:
    y=yaml.safe_load(open(inputFile.name).read())

  flat=flatten.json2json(y)

  if args.verbose:
    print('echo -e "yaml2bash requested keys from {f}: [{k}]" ; '.format(k=', '.join(inputKeys), f=inputFile.name))

  if args.checkExists:
    for k in inputKeys:
      snakeCaseKey=k.replace(".", "_")  
      if snakeCaseKey not in flat:
        exit(1)
    exit(0)
        

  for k in inputKeys:
    snakeCaseKey=k.replace(".", "_")
    print("export "+snakeCaseKey+"='"+str(flat[snakeCaseKey])+"'; ")