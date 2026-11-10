subroutine firs_stack_center_mass_calculation(Rocket)
    use rocket_types
    implicit none
    type(Rocket_t) Rocket
    integer i, tank_index
    type(Element_t), dimension(Rocket%number_of_stages)   :: Engine           ! the dimension indicates the stage for each element 
    type(Element_t), dimension(Rocket%number_of_stages)   :: Thrust_str
    type(Element_t), dimension(Rocket%number_of_stages,2) :: Tank             ! Oxidizer and fuel tanks include insulation
                                                            ! 1 = fuel tank | 2 = Oxidizer tank 
    type(Element_t), dimension(Rocket%number_of_stages)   :: Avionics
    type(Element_t), dimension(Rocket%number_of_stages)   :: Inter_stage_str
    type(Element_t), dimension(Rocket%number_of_stages)   :: Unpr_str
    type(Element_t), dimension(Rocket%number_of_stages)   :: Wiring
    type(Element_t), dimension(Rocket%number_of_stages)   :: Fuel 
    type(Element_t), dimension(Rocket%number_of_stages)   :: Oxidizer 
    
    type(Element_t) Payload ! Rocket payload
    
    real(8) X   ! [m] aux. variable for defining position
    real(8) dome_height, tank_height

    ! This loop defines the elements as point or distributed masses
    do i=1, Rocket%number_of_stages
        Engine(i)%point_mass          = .True.
        Thrust_str(i)%point_mass      = .True.
        Tank(i,1)%point_mass          = .False.
        Tank(i,2)%point_mass          = .False.
        Avionics(i)%point_mass        = .True.
        Inter_stage_str(i)%point_mass = .False.
        Unpr_str(i)%point_mass        = .False.
        Wiring(i)%point_mass          = .False.
        Fuel(i)%point_mass            = .False.
        Oxidizer(i)%point_mass        = .False.
    end do
    Payload%point_mass = .False.

    ! This loop defines the mass of each element
    do i=1, Rocket%number_of_stages
        Engine(i)%mass          = Rocket%stage(i)%m_engines
        Thrust_str(i)%mass      = Rocket%stage(i)%m_thrust_structure
        Tank(i,1)%mass          = Rocket%stage(i)%tank(1)%m_shell + Rocket%stage(i)%tank(1)%m_insulation
        Tank(i,2)%mass          = Rocket%stage(i)%tank(2)%m_shell + Rocket%stage(i)%tank(2)%m_insulation
        Avionics(i)%mass        = Rocket%stage(i)%m_avionics
        Inter_stage_str(i)%mass = Rocket%stage(i)%m_inter_stage_str
        Unpr_str(i)%mass        = Rocket%stage(i)%m_unpr_str
        Wiring(i)%mass          = Rocket%stage(i)%m_wiring
        Fuel(i)%mass            = Rocket%stage(i)%tank(1)%m_liq
        Oxidizer(i)%mass        = Rocket%stage(i)%tank(2)%m_liq
    end do
    Payload%mass = Rocket%rm_L

    ! This loop defines the position of the lowest point of each sub_systems element
    X = 0.d0 ! Start at the base of the rocket
    do i=1, Rocket%number_of_stages
        Engine(i)%LP_position     = X
        Thrust_str(i)%LP_position = X
        Wiring(i)%LP_position     = X
        Unpr_str(i)%LP_Position   = X


        do tank_index = 1, 2
            Tank(i,tank_index)%LP_position = X 
            if (Rocket%stage(i)%tank(tank_index)%Geometry == 1) then       ! Cylindrical Tank
                dome_height = Rocket%stage(i)%Diameter /(2.d0 * Rocket%stage(i)%tank(tank_index)%dome_AR)
                tank_height = 2*dome_height + Rocket%stage(i)%tank(tank_index)%h_cyl
            else if (Rocket%stage(i)%tank(tank_index)%Geometry == 2) then  ! Spherical Tank
                dome_height = Rocket%stage(i)%Diameter /(2.d0 * Rocket%stage(i)%tank(tank_index)%dome_AR)
                tank_height = 2*dome_height
            else if (Rocket%stage(i)%tank(tank_index)%Geometry == 3) then  ! Toroidal Tank 
                tank_height = 2*Rocket%stage(i)%tank(tank_index)%Circular_section_radius
            end if
            X = X + tank_height ! Move to the top of the tank
        end do
        Fuel(i)%LP_position     = Tank(i,1)%LP_position 
        Oxidizer(i)%LP_position = Tank(i,2)%LP_position

        Avionics(i)%LP_position        = X
        Inter_stage_str(i)%LP_position = X

        X = X + Rocket%stage(i)%L_inter_stage_str ! Move to start of next stage
    end do
end subroutine