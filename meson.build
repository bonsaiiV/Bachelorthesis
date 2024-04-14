project('Bachelorthesis', 'c')

cc = meson.get_compiler('c')
math_dep = cc.find_library('m')
gsl_dep = dependency('gsl')
omp = dependency('openmp')
fft_lib = library('fix_fft',
  'highlevel_dfts/fix_fft.c',
  dependencies : [math_dep, omp],
)
mul_test = executable('test-fixed-mult',
  'highlevel_dfts/tests/fixed-multiplication.c',
  link_with : fft_lib
)
test('fixed-multiplication', mul_test)
executable('fft_acc',
  'highlevel_dfts/fft_accuracy.c',
  dependencies: [gsl_dep],
  link_with : fft_lib
)
