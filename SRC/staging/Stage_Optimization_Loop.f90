subroutine STAGING_LOOP(Rocket)
    use typical_data
    use rocket_types
    use constants
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    integer i
    real(8) DV_old, DV_new !old and new Delta_v iterations
    real(8) err            !difference between 2 iterations of Delta_v
    real(8) V_ast, V_circ           !V* en LaunchMethodology

    Rocket%rt_burn = 0.d0
    do i=1, Rocket%number_of_stages
        Rocket%rt_burn = Rocket%rt_burn + Rocket%stage(i)%t_burn
    end do

    V_circ = delta_v
    V_ast = sqrt(V_circ**2.d0 + 2.d0*g_0*orbit_height*(Radius/(Radius+orbit_height))**2.d0)
    DV_old = V_ast + 1.5e-3*Rocket%rt_burn**2.d0 + 8.82e-2*Rocket%rt_burn + 1036.d0

    do while(err < 1e-3)

        call STAGING(Rocket)    

        call DV_loss(Rocket,DV_new)   
        
        err = abs(DV_old - DV_new)

        DV_old=DV_new
        print*, DV_new

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
    real(8) DV_old, DV_new, V_rot, V_circ       !VARIABLES COMUNES PARA AMBOS CALCULOS
    real(8) err            !difference between 2 iterations of Delta_v

    V_circ=delta_v

  !  K1 = 662.1d0 + 1.602d0*orbit_height + 1.224e-3*orbit_height**2.d0
    
 !   K2 = 1.7871 - 9.687e-4*orbit_height
 
  !  DV_loss1 = K1 + K2*Rocket%rt_burn
    
    K3 = 429.9d0 + 1.602d0*orbit_height + 1.224e-3*orbit_height**2.d0

    K4 = 2.328d0 - 9.687e-4*orbit_height
   

    expo = -0.333d0*DV_loss2/(g_0*ISP)

    T_3s = 3*(1-exp(expo))*g_0*ISP/A0

    T_mix = 0.405d0*Rocket%rt_burn + 0.595d0*T_3s

    DV_loss2 = K3 + K4*T_mix

    DV_new = V_circ + DV_loss2 - V_rot      !V_circ + DV_loss1 - V_rot si usamos el metodo sin refinar

end subroutine DV_loss
