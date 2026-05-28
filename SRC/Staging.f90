subroutine STAGING(Rocket)
    use typical_data 
    use rocket_types
    use constants
    implicit none
    type(Rocket_t), intent(inout) :: Rocket 
    real(8) L                     ! Lagrange multiplier
    real(8) Ln                    ! Previous L value 
    real(8) h, res, g

    integer i 

    do i=1, Rocket%number_of_stages
        Rocket%stage(i)%nu_e = Rocket%stage(i)%ISP * g_0 !Eq 3
    end do

    !===== L is solved using eq 19 =======================================
    L = 0.5d0
    i = 0
    h = 1.e-3 
    do while (res < 1.e-3 .and. i < 100)
        Ln = L
        L  = L - g(L, Rocket)*2*h/(g(L+h, Rocket) - g(L-h, Rocket)) 

        i = i + 1
        res = abs(L - Ln)
    end do
    !=====================================================================

    !===== The mass ratios for each stage are solved using eq 18 =========
        Rocket%stage(:)%k_m = (1.d0 + L*Rocket%stage(:)%nu_e) &
            /(L*Rocket%stage(:)%nu_e*Rocket%stage(:)%k_s)    
    !=====================================================================

    do i=1, Rocket%number_of_stages
        Rocket%stage(i)%m_p = Rocket%stage(i)%m_0 - (Rocket%stage(i)%m_0)/(Rocket%stage(i)%k_m) 
        if (i < Rocket%number_of_stages) then
            Rocket%stage(i+1)%m_0 = Rocket%stage(i)%m_0 - &
                Rocket%stage(i)%m_p - Rocket%stage(i)%m_s 
        end if 
    end do

end subroutine

function g(L, Rocket)
    use typical_data
    use rocket_types 
    implicit none
    type(Rocket_t), intent(in) :: Rocket
    real(8), intent(in) :: L 
    real(8) g 
    real(8) sum
    integer i

    sum = 0.d0
    do i=1, Rocket%number_of_stages
        sum = sum + Rocket%stage(i)%nu_e * log((1.d0+L*Rocket%stage(i)%nu_e) & 
            /(L*Rocket%stage(i)%nu_e*Rocket%stage(i)%k_s)) 
    end do

    g = delta_V - sum 
end function