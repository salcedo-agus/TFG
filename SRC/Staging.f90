subroutine STAGING(Rocket)
    use typical_data 
    use rocket_types
    implicit none
    type(Rocket_t), intent(inout) :: Rocket 
    real(8) L                     ! Lagrange multiplier
    real(8) Ln                    ! Previous L value 
    real(8) h, res, g

    integer i 


    !===== L is solve using eq 19 ========================================
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

    !===== The mass ratios for each stage are solve using eq 18 ==========
        Rocket%rocket_stages(:)%k_m = (1.d0 + L*Rocket%rocket_stages(:)%nu_e) &
            /(L*Rocket%rocket_stages(:)%nu_e*Rocket%rocket_stages(:)%k_s)    
    !=====================================================================


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
        sum = sum + Rocket%rocket_stages(i)%nu_e * log((1.d0+L*Rocket%rocket_stages(i)%nu_e) & 
            /(L*Rocket%rocket_stages(i)%nu_e*Rocket%rocket_stages(i)%k_s)) 
    end do

    g = delta_V - sum 
end function