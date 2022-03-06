local ranges = {
  first_return_var = {
    parent = {
      parent = {
        parent = {
          parent = {
            parent = {
              parent = {
                parent = {
                  parent = {
                    parent = {
                      parent = {
                        range = {
                          start = { line = 0, character = 0 },
                          ['end'] = { line = 10, character = 0 },
                        },
                      },
                      range = {
                        start = { line = 2, character = 0 },
                        ['end'] = { line = 9, character = 1 },
                      },
                    },
                    range = {
                      start = { line = 3, character = 0 },
                      ['end'] = { line = 9, character = 1 },
                    },
                  },
                  range = {
                    start = { line = 3, character = 1 },
                    ['end'] = { line = 9, character = 0 },
                  },
                },
                range = {
                  start = { line = 4, character = 0 },
                  ['end'] = { line = 6, character = 5 },
                },
              },
              range = {
                start = { line = 4, character = 4 },
                ['end'] = { line = 6, character = 5 },
              },
            },
            range = {
              start = { line = 4, character = 24 },
              ['end'] = { line = 6, character = 5 },
            },
          },
          range = {
            start = { line = 4, character = 25 },
            ['end'] = { line = 6, character = 4 },
          },
        },
        range = {
          start = { line = 5, character = 0 },
          ['end'] = { line = 5, character = 22 },
        },
      },
      range = {
        start = { line = 5, character = 8 },
        ['end'] = { line = 5, character = 22 },
      },
    },
    range = {
      start = { line = 5, character = 15 },
      ['end'] = { line = 5, character = 21 },
    },
  },
  last_return_var = {
    parent = {
      parent = {
        parent = {
          parent = {
            parent = {
              parent = {
                range = {
                  start = { line = 0, character = 0 },
                  ['end'] = { line = 10, character = 0 },
                },
              },
              range = {
                start = { line = 2, character = 0 },
                ['end'] = { line = 9, character = 1 },
              },
            },
            range = {
              start = { line = 3, character = 0 },
              ['end'] = { line = 9, character = 1 },
            },
          },
          range = {
            start = { line = 3, character = 1 },
            ['end'] = { line = 9, character = 0 },
          },
        },
        range = {
          start = { line = 8, character = 0 },
          ['end'] = { line = 8, character = 17 },
        },
      },
      range = {
        start = { line = 8, character = 4 },
        ['end'] = { line = 8, character = 17 },
      },
    },
    range = {
      start = { line = 8, character = 11 },
      ['end'] = { line = 8, character = 16 },
    },
  },
}

local simple_php = {
  file_path = './lua/lsp-selection-range/tests/fixtures/simple.php',
  selection_ranges = {
    from_first_return = {
      full_file = ranges.first_return_var.parent.parent.parent.parent.parent.parent.parent.parent,
      full_function = ranges.first_return_var.parent.parent.parent.parent.parent.parent.parent,
      function_body_with_braces = ranges.first_return_var.parent.parent.parent.parent.parent.parent,
      function_body_without_braces = ranges.first_return_var.parent.parent.parent.parent.parent,
      full_if_with_starting_spaces = ranges.first_return_var.parent.parent.parent.parent.parent,
      full_if_without_starting_spaces = ranges.first_return_var.parent.parent.parent.parent,
      if_body_with_braces = ranges.first_return_var.parent.parent.parent.parent,
      if_body_without_braces = ranges.first_return_var.parent.parent.parent,
      return_stmt_line = ranges.first_return_var.parent.parent,
      return_stmt = ranges.first_return_var.parent,
      variable = ranges.first_return_var,
    },
    from_last_return = {
      full_file = ranges.last_return_var.parent.parent.parent.parent.parent.parent,
      full_function = ranges.last_return_var.parent.parent.parent.parent.parent,
      function_body_with_braces = ranges.last_return_var.parent.parent.parent.parent,
      function_body_without_braces = ranges.last_return_var.parent.parent.parent,
      return_stmt_line = ranges.last_return_var.parent.parent,
      return_stmt = ranges.last_return_var.parent,
      variable = ranges.last_return_var,
    },
  },
  ranges = {
    from_if_to_last_return = {
      start = { line = 4, character = 11 },
      ['end'] = { line = 8, character = 15 },
    },
  },
  positions = {
    on_first_return_var = { line = 5, character = 18 },
    on_last_return_var = { line = 8, character = 15 },
    end_of_selection_from_if_to_last_return = { line = 8, character = 14 },
  },
}

local client_helper = require('lsp-selection-range.tests.helpers.client')

function simple_php.get_client()
  local client = client_helper.create_client()

  client.will_respond_for_position(simple_php.positions.on_first_return_var, { ranges.first_return_var })
  client.will_respond_for_position(simple_php.positions.on_last_return_var, { ranges.last_return_var })
  client.will_respond_for_position(
    simple_php.positions.end_of_selection_from_if_to_last_return,
    { ranges.last_return_var }
  )

  return client
end

return simple_php
