subroutine STAGING_LOOP(Rocket)
    use typical_data
    use rocket_types
    use constants
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    real(8) DV_old, DV_new !old and new Delta_v iterations
    real(8) err            !difference between 2 iterations of Delta_v
    real(8) V_ast, T_a           !V* en LaunchMethodology
    integer i

    if (number_of_stages == 1) then 
        T_a = 180.d0
    else if (number_of_stages == 2) then
        T_a = 520.d0
    else if (number_of_stages >= 3) then
        T_a = 820.d0
    else
        T_a = 0.d0
        print*, 'Ascent time 0'
    end if

    Rocket%DV_loss = 0.d0
    t_a=400.d0
    V_ast = sqrt(V_circ**2.d0 + 2.d0*g_0*orbit_height*(Radius/(Radius+orbit_height))**2.d0)
    DV_old = V_ast + 1.5e-3*T_a**2.d0 + 8.82e-2*T_a + 1036.d0
    print*, "DV INICIAL", DV_old 
    stop
    Rocket%delta_v = DV_old
    !delta_v = 10.d0

    err = 1.d0
    i = 0
    do while(err > 1e-3 .and. i<50)
        i=i+1
      !  print*, delta_v

        call STAGING(Rocket)    

        call stage_Thrust_calculator(Rocket)

        call DV_loss(Rocket, DV_new)   
        
        err = abs(DV_old - DV_new)

        DV_old = DV_new
        print*, 'Delta_V = ', DV_new
        Rocket%delta_v = DV_new
    end do

end subroutine STAGING_LOOP

subroutine DV_loss(Rocket,DV_new)
    use typical_data
    use rocket_types
    use constants
    !ACA IRIA MODULO DE ORBITAS CON DATOS VCIRC Y HP
    !FALTARIA TAMBIEN UN MODULO QUE TENGA DATOS DEL LUGAR DE LANZAMIENTO PARA SACAR V_rot
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    integer i
    real(8) K1, K2,  DV_loss1           !VARIABLES PARA EL CALCULO DE DV_loss1
    real(8) K3, K4, DV_loss2, T_3s, ISP, A0, T_mix, expo      !VARIABLES PARA EL CALCULO DE DV_loss2
    real(8) DV_old, DV_new, V_rot       !VARIABLES COMUNES PARA AMBOS CALCULOS
    real(8) err            !difference between 2 iterations of Delta_v

    V_rot = 0.d0

    !DV_loss2 = 0.d0

  !  K1 = 662.1d0 + 1.602d0*orbit_height + 1.224e-3*orbit_height**2.d0
    
 !   K2 = 1.7871 - 9.687e-4*orbit_height
 
  !  DV_loss1 = K1 + K2*Rocket%rt_burn
    
    K3 = 429.9d0 + 1.602d0*orbit_height + 1.224e-3*orbit_height**2.d0

    K4 = 2.328d0 - 9.687e-4*orbit_height

    expo = -0.333d0*V_circ / (g_0*Rocket%ISP_mean)

    A0 = rocket%stage(1)%T / rocket%rm_0  
    
    T_3s = 3*(1-exp(expo)) * g_0*Rocket%ISP_mean / A0

    T_mix = 0.405d0*Rocket%rt_burn + 0.595d0*T_3s

    Rocket%DV_loss = K3 + K4*T_mix

    print*, 'Delta_V_loss = ', DV_loss2

    DV_new = V_circ + Rocket%DV_loss - V_rot      !V_circ + DV_loss1 - V_rot si usamos el metodo sin refinar

end subroutine DV_loss
