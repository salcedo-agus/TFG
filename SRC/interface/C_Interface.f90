module c_interface
    use iso_c_binding
    use rocket_types
    use typical_data
    implicit none

contains

subroutine run_staging(                         &
    n_stages,                                   &
    delta_v_in, payload_mass_in,                &
    isp_in, ks_in,                              &
    m0_out, mf_out, mp_out, ms_out,             &
    km_out, ks_out, kl_out,                     &
    nu_e_out, total_m0_out, minimum_found_out   &
    ) bind(C, name="run_staging")

    integer(c_int),  intent(in)  :: n_stages        ! no VALUE
    real(c_double),  intent(in)  :: delta_v_in      ! no VALUE
    real(c_double),  intent(in)  :: payload_mass_in ! no VALUE
    real(c_double),  intent(in)  :: isp_in(n_stages)
    real(c_double),  intent(in)  :: ks_in(n_stages)

    real(c_double),  intent(out) :: m0_out(n_stages)
    real(c_double),  intent(out) :: mf_out(n_stages)
    real(c_double),  intent(out) :: mp_out(n_stages)
    real(c_double),  intent(out) :: ms_out(n_stages)
    real(c_double),  intent(out) :: km_out(n_stages)
    real(c_double),  intent(out) :: ks_out(n_stages)
    real(c_double),  intent(out) :: kl_out(n_stages)
    real(c_double),  intent(out) :: nu_e_out(n_stages)
    real(c_double),  intent(out) :: total_m0_out
    integer(c_int),  intent(out) :: minimum_found_out

    type(Rocket_t) :: Rocket
    integer        :: i, check_count
    real(c_double) :: L_i, check

    ! --- Set module-level globals used by STAGING ---
    Rocket%delta_v          = delta_v_in
    payload_mass     = payload_mass_in
    number_of_stages = n_stages

    ! --- Build Rocket struct ---
    Rocket%number_of_stages = n_stages
    allocate(Rocket%stage(n_stages))

    do i = 1, n_stages
        Rocket%stage(i)%ISP = isp_in(i)
        Rocket%stage(i)%k_s = ks_in(i)
    end do

    ! --- Run the solver ---
    call STAGING(Rocket)

    ! --- Pack results into flat arrays for Python ---
    do i = 1, n_stages
        m0_out(i)   = Rocket%stage(i)%m_0
        mf_out(i)   = Rocket%stage(i)%m_f
        mp_out(i)   = Rocket%stage(i)%m_p
        ms_out(i)   = Rocket%stage(i)%m_s
        km_out(i)   = Rocket%stage(i)%k_m
        ks_out(i)   = Rocket%stage(i)%k_s
        kl_out(i)   = Rocket%stage(i)%k_L
        nu_e_out(i) = Rocket%stage(i)%nu_e
    end do

    total_m0_out = Rocket%rm_0

    ! --- BUG FIX: evaluate the minimum condition (eq 26) for every stage ---
    ! From eq 18:  k_m = (L*nu_e - 1) / (L*nu_e*k_s)
    ! Rearranging: L = 1 / (nu_e * (1 - k_s*k_m))
    ! Eq 26 check: L*nu_e*(1 - k_s*k_m)^2 - 1 + 2*k_s*k_m > 0
    check_count = 0
    do i = 1, n_stages
        ! Guard against degenerate denominator
        if (abs(Rocket%stage(i)%nu_e * (1.d0 - Rocket%stage(i)%k_s * Rocket%stage(i)%k_m)) > 1.d-12) then
            L_i = 1.d0 / (Rocket%stage(i)%nu_e * (1.d0 - Rocket%stage(i)%k_s * Rocket%stage(i)%k_m))
            check = L_i * Rocket%stage(i)%nu_e &
                    * (1.d0 - Rocket%stage(i)%k_s * Rocket%stage(i)%k_m)**2 &
                    - 1.d0 + 2.d0 * Rocket%stage(i)%k_s * Rocket%stage(i)%k_m
            if (check > 0.d0) check_count = check_count + 1
        end if
    end do

    if (check_count == n_stages) then
        minimum_found_out = 1
    else
        minimum_found_out = 0
    end if

    deallocate(Rocket%stage)

end subroutine run_staging

end module c_interface
