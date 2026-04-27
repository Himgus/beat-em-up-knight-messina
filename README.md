Hola profe! Disculpa por seguir actualizando el juego hasta hoy, no medí bien el tiempo y me atrase mucho. Esto es lo que quedó, cambie un montón desde el objetivo original mas que nada por la falta de sprites.

Controles:
AD - moverse
J - atacar
L - roll(en el piso)/dash(en el aire)
K - activar habilidades(cuestan vida pero nunca te matan)
L mantenido - correr

ataque especial - correr, saltar y atacar.

ataques que son afectados por habilidades: segundo ataque basico, ataque especial.

Los arqueros no pude terminar de idear como funcionarían, les hice sus propios nodos "slots" como a los enemigos en la escena de de player unicamente en la parte derecha por un tema de camara. Cuando spawnean se mueven hacia los mismos y desde ahi disparan. Se concentran unicamente en llegar al nodo cuando no estan en él. Se podria arreglar poniendo un rango en x "cómodo" para estos enemigos dependiendo del jugador.

El enemigo común podría tener un ataque más pero no llegue a hacerlo.

Otro problema que tuve fue el tener que basar todo el desarrollo de personajes en un animatedsprite2d porque mi protagonista no tenía un png con todas las animaciones juntas para usar animation player. Hubiera sido muchísimo más simple porque se pueden poner metodos en frames especificos de las animaciones sin necesidad de agregar código. No encontré la manera de hacerlo funcionar lamentablemente.

El sistema de estados que usé lo saque de un tutorial pero es verdaderamente feo de ver y complicado de entender a veces. Alargó el código mucho. Creería que se puede desarrollar sin este sistema y sería mucho más fácil.
