module c_interface
    use iso_c_binding
    use rocket_types
    use typical_data
    use constants
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

    ! --- Initialize Rocket%rm_L (G-01-2) ---
    ! Mirror the console path (Payload_Mass_calc.f90:11-19, PAF eq. 11:
    ! m_adapter = 0.0755*payload_mass + 50) so both paths share one formula.
    ! Without this, Staging.f90:86/106 read uninitialized stack memory on the
    ! ctypes/GUI path, producing null/NaN masses in the Results tab.
    Rocket%rm_L = payload_mass + 0.0755d0 * payload_mass + 50.d0

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

subroutine run_full_pipeline(                   &
    n_stages,                                   &
    orbit_height_in, payload_mass_in,           &
    isp_in, ks_in, propellant_in,               &
    diameter_setup_in, user_diameter_in,        &
    m0_out, mf_out, mp_out, ms_out,             &
    km_out, ks_out, kl_out, nu_e_out,           &
    dv_out, diameter_out, length_out, volume_out, &
    total_m0_out, v_circ_out, minimum_found_out &
    ) bind(C, name="run_full_pipeline")

    integer(c_int),  intent(in)  :: n_stages        ! no VALUE
    real(c_double),  intent(in)  :: orbit_height_in ! no VALUE
    real(c_double),  intent(in)  :: payload_mass_in ! no VALUE
    real(c_double),  intent(in)  :: isp_in(n_stages)
    real(c_double),  intent(in)  :: ks_in(n_stages)
    integer(c_int),  intent(in)  :: propellant_in(n_stages)

    integer(c_int),  intent(in)  :: diameter_setup_in ! no VALUE
    real(c_double),  intent(in)  :: user_diameter_in  ! no VALUE

    real(c_double),  intent(out) :: m0_out(n_stages)
    real(c_double),  intent(out) :: mf_out(n_stages)
    real(c_double),  intent(out) :: mp_out(n_stages)
    real(c_double),  intent(out) :: ms_out(n_stages)
    real(c_double),  intent(out) :: km_out(n_stages)
    real(c_double),  intent(out) :: ks_out(n_stages)
    real(c_double),  intent(out) :: kl_out(n_stages)
    real(c_double),  intent(out) :: nu_e_out(n_stages)
    real(c_double),  intent(out) :: dv_out(n_stages)
    real(c_double),  intent(out) :: diameter_out(n_stages)
    real(c_double),  intent(out) :: length_out(n_stages)
    real(c_double),  intent(out) :: volume_out(n_stages)
    real(c_double),  intent(out) :: total_m0_out
    real(c_double),  intent(out) :: v_circ_out
    integer(c_int),  intent(out) :: minimum_found_out

    type(Rocket_t) :: Rocket
    integer        :: i, check_count
    real(c_double) :: L_i, check

    ! --- Seed module-level globals read by the pipeline ---
    payload_mass          = payload_mass_in
    number_of_stages      = n_stages
    orbit_height          = orbit_height_in        ! [km], GUI units
    diameter_setup        = diameter_setup_in
    user_defined_diameter = user_diameter_in

    ! Propellant indices are combo-derived 1..8 (GUI codes matching the Fortran
    ! select cases); the min(i, n_stages) fallback keeps every stage slot in
    ! range, so Geometry_calc select cases never hit `case default`.
    first_stage_propellant_and_oxidizer  = propellant_in(1)
    second_stage_propellant_and_oxidizer = propellant_in(min(2, n_stages))
    third_stage_propellant_and_oxidizer  = propellant_in(min(3, n_stages))

    ! --- Build Rocket struct ---
    Rocket%number_of_stages = n_stages
    allocate(Rocket%stage(n_stages))

    do i = 1, n_stages
        Rocket%stage(i)%ISP = isp_in(i)
        Rocket%stage(i)%k_s = ks_in(i)
    end do

    ! --- Run the full console-path pipeline (Main.f90:11-17 order) ---
    call Payload_Mass_calculator(Rocket)   ! sets Rocket%rm_L (PAF eq. 11)

    call orbit_speed_calculator            ! sets V_circ global BEFORE STAGING_LOOP

    call STAGING_LOOP(Rocket)              ! converged loop, not single STAGING

    call rocket_geometry_calculation(Rocket)

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
        dv_out(i)        = Rocket%stage(i)%D_v
        diameter_out(i)  = Rocket%stage(i)%Diameter
        length_out(i)    = Rocket%stage(i)%Length
        volume_out(i)    = pi * Rocket%stage(i)%Diameter**2 &
                           * Rocket%stage(i)%Length / 4.d0   ! Geometry_calc.f90:105 identity
    end do

    total_m0_out = Rocket%rm_0
    v_circ_out   = V_circ

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

end subroutine run_full_pipeline

end module c_interface
