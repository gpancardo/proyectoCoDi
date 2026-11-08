// node web/cuenta.test.mjs
import assert from 'node:assert/strict'
import { armarCuenta } from './cuenta.js'

const total = (t) => armarCuenta(t).cuentas.map((c) => c.total)

assert.deepEqual(total('10 tacos de canasta'), [120])
assert.deepEqual(total('10 tacos de canasta y 2 aguas de horchata'), [170])
assert.deepEqual(total('dos tamales de rajas, un atole'), [56])
assert.deepEqual(total('Un kilo de tortillas'), [24])
assert.deepEqual(total('media docena de tacos'), [72])
assert.deepEqual(total('3 tacos y 3 tacos'), [72], 'suma el mismo producto')
assert.equal(armarCuenta('2 tacos y 1 refresco').cuentas.length, 2, 'una cuenta por negocio')
assert.deepEqual(total('2 aguas'), [30], '"agua" sola es agua natural, no horchata')
assert.deepEqual(armarCuenta('una pizza').sinMatch, ['una pizza'])
assert.deepEqual(armarCuenta('500 tacos').sinMatch, ['500 tacos'], 'cantidad fuera de rango')
assert.deepEqual(total(''), [])
console.log('cuenta: ok')
