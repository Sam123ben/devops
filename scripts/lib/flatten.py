#flatten nested json to one level

def json2json(nested_json):
  out={}
  def flatten(x, name=''):
    if type(x) is dict:
      for a in x:
        flatten(x[a], name + a + '_')
    elif type(x) is list:
      i = 0
      for a in x:
        flatten(a, name + str(i) + '_')
        i += 1
    else:
      out[name[:-1]] = x
  flatten(nested_json)
  return out