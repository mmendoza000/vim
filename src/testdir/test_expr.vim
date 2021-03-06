" Tests for expressions.

func Test_equal()
  let base = {}
  func base.method()
    return 1
  endfunc
  func base.other() dict
    return 1
  endfunc
  let instance = copy(base)
  call assert_true(base.method == instance.method)
  call assert_true([base.method] == [instance.method])
  call assert_true(base.other == instance.other)
  call assert_true([base.other] == [instance.other])

  call assert_false(base.method == base.other)
  call assert_false([base.method] == [base.other])
  call assert_false(base.method == instance.other)
  call assert_false([base.method] == [instance.other])

  call assert_fails('echo base.method > instance.method')
endfunc

func Test_version()
  call assert_true(has('patch-7.4.001'))
  call assert_true(has('patch-7.4.01'))
  call assert_true(has('patch-7.4.1'))
  call assert_true(has('patch-6.9.999'))
  call assert_true(has('patch-7.1.999'))
  call assert_true(has('patch-7.4.123'))

  call assert_false(has('patch-7'))
  call assert_false(has('patch-7.4'))
  call assert_false(has('patch-7.4.'))
  call assert_false(has('patch-9.1.0'))
  call assert_false(has('patch-9.9.1'))
endfunc

func Test_dict()
  let d = {'': 'empty', 'a': 'a', 0: 'zero'}
  call assert_equal('empty', d[''])
  call assert_equal('a', d['a'])
  call assert_equal('zero', d[0])
  call assert_true(has_key(d, ''))
  call assert_true(has_key(d, 'a'))

  let d[''] = 'none'
  let d['a'] = 'aaa'
  call assert_equal('none', d[''])
  call assert_equal('aaa', d['a'])
endfunc

func Test_strgetchar()
  call assert_equal(char2nr('a'), strgetchar('axb', 0))
  call assert_equal(char2nr('x'), strgetchar('axb', 1))
  call assert_equal(char2nr('b'), strgetchar('axb', 2))

  call assert_equal(-1, strgetchar('axb', -1))
  call assert_equal(-1, strgetchar('axb', 3))
  call assert_equal(-1, strgetchar('', 0))
endfunc

func Test_strcharpart()
  call assert_equal('a', strcharpart('axb', 0, 1))
  call assert_equal('x', strcharpart('axb', 1, 1))
  call assert_equal('b', strcharpart('axb', 2, 1))
  call assert_equal('xb', strcharpart('axb', 1))

  call assert_equal('', strcharpart('axb', 1, 0))
  call assert_equal('', strcharpart('axb', 1, -1))
  call assert_equal('', strcharpart('axb', -1, 1))
  call assert_equal('', strcharpart('axb', -2, 2))

  call assert_equal('a', strcharpart('axb', -1, 2))
endfunc

func Test_getreg_empty_list()
  call assert_equal('', getreg('x'))
  call assert_equal([], getreg('x', 1, 1))
  let x = getreg('x', 1, 1)
  let y = x
  call add(x, 'foo')
  call assert_equal(['foo'], y)
endfunc

func Test_loop_over_null_list()
  let null_list = test_null_list()
  for i in null_list
    call assert_true(0, 'should not get here')
  endfor
endfunc

func Test_compare_null_dict()
  call assert_fails('let x = test_null_dict()[10]')
  call assert_equal({}, {})
  call assert_equal(test_null_dict(), test_null_dict())
  call assert_notequal({}, test_null_dict())
endfunc

func Test_set_reg_null_list()
  call setreg('x', test_null_list())
endfunc

func Test_special_char()
  " The failure is only visible using valgrind.
  call assert_fails('echo "\<C-">')
endfunc

func Test_option_value()
  " boolean
  set bri
  call assert_equal(1, &bri)
  set nobri
  call assert_equal(0, &bri)

  " number
  set ts=1
  call assert_equal(1, &ts)
  set ts=8
  call assert_equal(8, &ts)

  " string
  exe "set cedit=\<Esc>"
  call assert_equal("\<Esc>", &cedit)
  set cpo=
  call assert_equal("", &cpo)
  set cpo=abcdefgi
  call assert_equal("abcdefgi", &cpo)
  set cpo&vim
endfunc

function Test_printf_64bit()
  if has('num64')
    call assert_equal("123456789012345", printf('%d', 123456789012345))
  endif
endfunc

function Test_printf_spec_s()
  " number
  call assert_equal("1234567890", printf('%s', 1234567890))

  " string
  call assert_equal("abcdefgi", printf('%s', "abcdefgi"))

  " float
  if has('float')
    call assert_equal("1.23", printf('%s', 1.23))
  endif

  " list
  let value = [1, 'two', ['three', 4]]
  call assert_equal(string(value), printf('%s', value))

  " dict
  let value = {'key1' : 'value1', 'key2' : ['list', 'value'], 'key3' : {'dict' : 'value'}}
  call assert_equal(string(value), printf('%s', value))

  " funcref
  call assert_equal('printf', printf('%s', function('printf')))

  " partial
  call assert_equal(string(function('printf', ['%s'])), printf('%s', function('printf', ['%s'])))
endfunc

function Test_printf_spec_b()
  call assert_equal("0", printf('%b', 0))
  call assert_equal("00001100", printf('%08b', 12))
  call assert_equal("11111111", printf('%08b', 0xff))
  call assert_equal("   1111011", printf('%10b', 123))
  call assert_equal("0001111011", printf('%010b', 123))
  call assert_equal(" 0b1111011", printf('%#10b', 123))
  call assert_equal("0B01111011", printf('%#010B', 123))
  call assert_equal("1001001100101100000001011010010", printf('%b', 1234567890))
  if has('num64')
    call assert_equal("11100000100100010000110000011011101111101111001", printf('%b', 123456789012345))
    call assert_equal("1111111111111111111111111111111111111111111111111111111111111111", printf('%b', -1))
  else
    call assert_equal("11111111111111111111111111111111", printf('%b', -1))
  endif
endfunc

func Test_substitute_expr()
  let g:val = 'XXX'
  call assert_equal('XXX', substitute('yyy', 'y*', '\=g:val', ''))
  call assert_equal('XXX', substitute('yyy', 'y*', {-> g:val}, ''))
  call assert_equal("-\u1b \uf2-", substitute("-%1b %f2-", '%\(\x\x\)',
			   \ '\=nr2char("0x" . submatch(1))', 'g'))
  call assert_equal("-\u1b \uf2-", substitute("-%1b %f2-", '%\(\x\x\)',
			   \ {-> nr2char("0x" . submatch(1))}, 'g'))

  call assert_equal('231', substitute('123', '\(.\)\(.\)\(.\)',
	\ {-> submatch(2) . submatch(3) . submatch(1)}, ''))

  func Recurse()
    return substitute('yyy', 'y*', {-> g:val}, '')
  endfunc
  call assert_equal('--', substitute('xxx', 'x*', {-> '-' . Recurse() . '-'}, ''))
endfunc

func Test_invalid_submatch()
  " This was causing invalid memory access in Vim-7.4.2232 and older
  call assert_fails("call substitute('x', '.', {-> submatch(10)}, '')", 'E935:')
endfunc

func Test_substitute_expr_arg()
  call assert_equal('123456789-123456789=', substitute('123456789',
	\ '\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)',
	\ {m -> m[0] . '-' . m[1] . m[2] . m[3] . m[4] . m[5] . m[6] . m[7] . m[8] . m[9] . '='}, ''))

  call assert_equal('123456-123456=789', substitute('123456789',
	\ '\(.\)\(.\)\(.\)\(a*\)\(n*\)\(.\)\(.\)\(.\)\(x*\)',
	\ {m -> m[0] . '-' . m[1] . m[2] . m[3] . m[4] . m[5] . m[6] . m[7] . m[8] . m[9] . '='}, ''))

  call assert_equal('123456789-123456789x=', substitute('123456789',
	\ '\(.\)\(.\)\(.*\)',
	\ {m -> m[0] . '-' . m[1] . m[2] . m[3] . 'x' . m[4] . m[5] . m[6] . m[7] . m[8] . m[9] . '='}, ''))

  call assert_fails("call substitute('xxx', '.', {m -> string(add(m, 'x'))}, '')", 'E742:')
  call assert_fails("call substitute('xxx', '.', {m -> string(insert(m, 'x'))}, '')", 'E742:')
  call assert_fails("call substitute('xxx', '.', {m -> string(extend(m, ['x']))}, '')", 'E742:')
  call assert_fails("call substitute('xxx', '.', {m -> string(remove(m, 1))}, '')", 'E742:')
endfunc

func Test_function_with_funcref()
  let s:f = function('type')
  let s:fref = function(s:f)
  call assert_equal(v:t_string, s:fref('x'))
  call assert_fails("call function('s:f')", 'E700:')
endfunc

func Test_funcref()
  func! One()
    return 1
  endfunc
  let OneByName = function('One')
  let OneByRef = funcref('One')
  func! One()
    return 2
  endfunc
  call assert_equal(2, OneByName())
  call assert_equal(1, OneByRef())
  let OneByRef = funcref('One')
  call assert_equal(2, OneByRef())
  call assert_fails('echo funcref("{")', 'E475:')
endfunc

func Test_setmatches()
  hi def link 1 Comment
  hi def link 2 PreProc
  let set = [{"group": 1, "pattern": 2, "id": 3, "priority": 4}]
  let exp = [{"group": '1', "pattern": '2', "id": 3, "priority": 4}]
  if has('conceal')
    let set[0]['conceal'] = 5
    let exp[0]['conceal'] = '5'
  endif
  call setmatches(set)
  call assert_equal(exp, getmatches())
endfunc
