module rocket_functions
    implicit none
contains
function g(L, Rocket)
    use typical_data
    use rocket_types 
    implicit none
    type(Rocket_t), intent(in) :: Rocket
    real(8), intent(in) :: L 
    real(8) sum
    real(8) g 
    !real(8) c1, c2, c3
    !real(8) e1, e2, e3
    integer i

    !c1 = Rocket%stage(1)%nu_e
    !c2 = Rocket%stage(2)%nu_e
    !c3 = Rocket%stage(3)%nu_e
    
    !e1 = Rocket%stage(1)%k_s
    !e2 = Rocket%stage(2)%k_s
    !e3 = Rocket%stage(3)%k_s

   ! g = delta_v - (c1*log((L*c1-1)/(c1*e1*L)) + c2*log((L*c2-1)/(c2*e2*L)) + c3*log((L*c3-1)/(c3*e3*L)))

   ! Signo como Don Edberg 
   ! sum = 0.d0
   ! do i=1, Rocket%number_of_stages
   !     sum = sum + Rocket%stage(i)%nu_e * log((1.d0+L*Rocket%stage(i)%nu_e) /(L*Rocket%stage(i)%nu_e*Rocket%stage(i)%k_s))
   ! end do
   ! g = delta_v - sum 

   ! Signo como en Orbital Mechanics  
    sum = 0.d0
    do i=1, Rocket%number_of_stages
        sum = sum + Rocket%stage(i)%nu_e * log((L*Rocket%stage(i)%nu_e-1.d0) /(L*Rocket%stage(i)%nu_e*Rocket%stage(i)%k_s))
    end do
    g = Rocket%delta_v - sum
end function
end module

subroutine STAGING(Rocket)
    use typical_data 
    use rocket_types
    use constants
    use Root_Finding_Methods
    use rocket_functions
    implicit none
    type(Rocket_t), intent(inout) :: Rocket 
    procedure(func_interface), pointer :: function_pointer
    real(8) a, b, tol             ! Bisection variables 
    real(8) L
    real(8) check                 ! used for minimum check
    integer check_count
    integer i, iterations

    print*, "DELTA V for staging:", Rocket%delta_v
    do i=1, Rocket%number_of_stages
        Rocket%stage(i)%nu_e = Rocket%stage(i)%ISP * g_0 / 1000.d0 ![km/s] Eq 3
      !  print*, Rocket%stage(i)%nu_e
    end do

    !===== L is solved using eq 19 =======================================
  ! L = 0.1d0
    function_pointer => g
    tol = 1e-5
    a = Bolzano_Interval_Start(function_pointer, Rocket)
    b = 1.d0 
    
    call Bolzano_Bisection(function_pointer, Rocket, a, b, tol, L, iterations)
    !call Newton_Raphson(f, Rocket)
    !=====================================================================
   
    !===== The mass ratios for each stage are solved using eq 18 =========
    do i=1, Rocket%number_of_stages
        Rocket%stage(i)%k_m = (L*Rocket%stage(i)%nu_e - 1.d0)/(L*Rocket%stage(i)%nu_e*Rocket%stage(i)%k_s)    
    end do
    !=====================================================================

    !===== The initial mass of the Rocket is solved using eq 20 ==========
    Rocket%stage(1)%m_0 = 1.d0 
    do i=1, Rocket%number_of_stages
        Rocket%stage(1)%m_0 = Rocket%stage(1)%m_0 * (Rocket%stage(i)%k_m*(1.d0-Rocket%stage(i)%k_s))&
            /(1.d0 - Rocket%stage(i)%k_m*Rocket%stage(i)%k_s) 
    end do 
    Rocket%stage(1)%m_0 = Rocket%rm_L * Rocket%stage(1)%m_0
    !=====================================================================

    !=== Propellant and structure masses are solved using eq 21 and 22 ===
    do i=1, Rocket%number_of_stages
        Rocket%stage(i)%m_p = Rocket%stage(i)%m_0 - (Rocket%stage(i)%m_0)/(Rocket%stage(i)%k_m) 
        Rocket%stage(i)%m_s = (Rocket%stage(i)%k_s*Rocket%stage(i)%m_p)/(1.d0 - Rocket%stage(i)%k_s)
        if (i < Rocket%number_of_stages) then
            !=== Next partial Rocket initial mass is solved using eq 23 ==
            Rocket%stage(i+1)%m_0 = Rocket%stage(i)%m_0 - Rocket%stage(i)%m_p - Rocket%stage(i)%m_s 
            !=============================================================
        end if 
    end do
    !=====================================================================

    !=== The payload mass of each stage is the initial mass of the next ==
    do i=1, Rocket%number_of_stages
        if (i < Rocket%number_of_stages) then
            Rocket%stage(i)%m_L = Rocket%stage(i+1)%m_0
        else
            Rocket%stage(i)%m_L = Rocket%rm_L
        end if
    end do
    !===================================================================== 

    !===== Payload ratio of each stage is solved using eq 1c =============
    do i=1, Rocket%number_of_stages
        Rocket%stage(i)%k_L = Rocket%stage(i)%m_L / Rocket%stage(i)%m_0 
    end do   
    !=====================================================================

    !===== Final mass of each stage ======================================
    do i=1, Rocket%number_of_stages
        Rocket%stage(i)%m_f = Rocket%stage(i)%m_0 - Rocket%stage(i)%m_p    
    end do
    !=====================================================================

    Rocket%rm_0 = Rocket%stage(1)%m_0

    !===== Minimum Check according to eq 26 ==============================
    check_count = 0
    do i=1, Rocket%number_of_stages
        check = L*Rocket%stage(i)%nu_e *(1.d0 - Rocket%stage(i)%k_s * Rocket%stage(i)%k_m)**2.d0 &
            - 1.d0 + 2.d0 * Rocket%stage(i)%k_s * Rocket%stage(i)%k_m
            if (check > 0) check_count = check_count + 1 
    end do 
    if (check_count == Rocket%number_of_stages) then
        print*, "Minimum found :)"
    else 
        print*, "Minimum not found :("    
    end if 
    !=====================================================================
    
    !===== Stage Dv calculation with the rocket equation =================
    do i=1, rocket%number_of_stages 
        rocket%stage(i)%D_v = rocket%stage(i)%nu_e * log(rocket%stage(i)%m_0/rocket%stage(i)%m_f) 
    end do
    !=====================================================================

    !===Initial mass of the stage calculation=============================
    do i=1, rocket%number_of_stages
        rocket%stage(i)%m_i = rocket%stage(i)%m_0 - rocket%stage(i)%m_L  
    end do
    !=====================================================================
end subroutine

 