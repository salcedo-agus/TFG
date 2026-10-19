# TFG

TFG es un software de ingeniería orientado al diseño conceptual de lanzadores espaciales, capaz de dimensionar configuraciones multietapa y simular su desempeño en misiones orbitales o suborbitales.

## Objetivos específicos

* Definir una metodología de diseño basada en el enfoque de ingeniería de sistemas aplicado a lanzadores.
* Implementar un modelo de misión que permita calcular los requerimientos de ∆V.
* Desarrollar un modelo de staging para configuraciones multietapa.
* Implementar modelos de masas estructurales y de propelente.
* Modelar sistemas de propulsión mediante parámetros característicos (Isp, T/W, perfiles de empuje).
* Implementar diversos modelos de entorno (gravedad y atmósfera).
* Desarrollar un simulador de trayectoria basado en un modelo de 3 grados de libertad.
* Implementar estrategias de guiado (pitch program y gravity turn).
* Validar los resultados mediante la comparación con lanzadores reales o con casos de referencia.

## Geometría de tanques toroidales

Durante `sub_systems_calculation(Rocket)`, si el volumen de un tanque es menor o igual que
`pi**2 * Diameter**3 / 32`, se calcula su radio de sección circular con el método de la secante
y se asigna la superficie toroidal `2*pi**2*(Diameter - 2*r)*r`. Este límite es el volumen
máximo de un toroide anular, que ocurre para `r = Diameter/4`. Para volúmenes superiores se
conserva la selección esférica o cilíndrica existente.
