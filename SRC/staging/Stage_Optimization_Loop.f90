subroutine STAGING_LOOP(Rocket)
    use typical_data
    use rocket_types
    use constants
    !ACA IRIA MODULO CON DATOS DE LA ORBITA, R, H, V_CIRC
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    integer i
    real(8) DV_old, DV_new !old and new Delta_v iterations
    real(8) err            !difference between 2 iterations of Delta_v
    real(8) V_or, V_circ           !V* en LaunchMethodology
    real(8) Ta                     !Tiempo de ascenso directo

    V_or = sqrt(V_circ**2.d0 + 2.d0*g*H*(R/(R+H))**2.d0)
    DV_old = V_or + 1.5e-3*Ta**2.d0 + 8.82e-2*Ta + 1036.d0
    do while(err < 1e-3)

        call STAGING(Rocket)    
        call DV_loss(Rocket,Ta,DV_new)   
        err = abs(DV_old - DV_new)
    end do
end subroutine STAGING_LOOP

subroutine DV_loss(Rocket,Ta)
    use typical_data
    use rocket_types
    use constants
    !ACA IRIA MODULO DE ORBITAS CON DATOS VCIRC Y HP
    !FALTARIA TAMBIEN UN MODULO QUE TENGA DATOS DEL LUGAR DE LANZAMIENTO PARA SACAR V_rot
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    integer i
    real(8) K1, K2, K3, K4, DV_loss1, DV_loss2, DV_new, V_rot, V_circ
    real(8) Hp, Ta
    real(8) err            !difference between 2 iterations of Delta_v

    K1 = 662.1d0 + 1.602d0*Hp + 1.224e-3*Hp**2.d0
    
    K2 = 1.7871 - 9.687e-4*Hp

 !   K3 = 429.9d0 + 1.602d0*Hp + 1.224e-3*Hp**2.d0

  !  K4 = 2.328d0 - 9.687e-4*Hp
    
    DV_loss1 = K1 + K2*Ta

    expo = -0.333d0*DV_loss/(g*ISP)

    T_3s = 3*(1-exp(expo))*g*ISP/A0

    T_mix = 0.405d0*Ta + 0.595d0*T_3s

   ! DV_loss2 = K3 + K4*T_mix

    DV_new = V_circ + DV_loss - V_rot

end subroutine DV_loss
