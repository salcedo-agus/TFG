module constants
    implicit none 
    real(8), parameter :: pi  = dacos(-1.d0) 
    real(8), parameter :: g_0 = 9.80665d0 ![m/s2] standard acceleration of gravity     
    real(8), parameter :: Radius = 6378.d0  ![km] Earths radius     
end module constants

module typical_data
    implicit none
    !====== OPCIÓN 2: ENTRADA DE DATOS EN TXT ====================
    real(8) First_stage_ISP_lower 
    real(8) First_stage_ISP_upper 
    real(8) First_stage_ISP_mean

    real(8) Second_stage_ISP_lower 
    real(8) Second_stage_ISP_upper 
    real(8) Second_stage_ISP_mean
    
    real(8) Third_stage_ISP_lower 
    real(8) Third_stage_ISP_upper 
    real(8) Third_stage_ISP_mean

    real(8) First_stage_ks_lower 
    real(8) First_stage_ks_upper 
    real(8) First_stage_ks_mean  

    real(8) Second_stage_ks_lower
    real(8) Second_stage_ks_upper 
    real(8) Second_stage_ks_mean   
    
    real(8) Third_stage_ks_lower 
    real(8) Third_stage_ks_upper 
    real(8) Third_stage_ks_mean  
    !=============================================================

    real(8) V_circ
    real(8) orbit_height
    real(8) payload_mass
    integer number_of_stages

    integer first_stage_propellant_and_oxidizer
    integer second_stage_propellant_and_oxidizer
    integer third_stage_propellant_and_oxidizer

    integer first_stage_combustion_cycle
    integer second_stage_combustion_cycle
    integer third_stage_combustion_cycle

    integer diameter_setup
    real(8) user_defined_diameter
contains

subroutine data_entry(Rocket)
    use rocket_types
    implicit none
    type(Rocket_t) Rocket 
    real(8) ISP_vector(3)   !These vectors always store the values of ISP and k_s 
    real(8) k_s_vector(3)   
    integer i

    call load_config("config.txt")

    print*, "============= DATA ENTRY =========="
    print*, "Number of stages= ", number_of_stages
    print*, "orbit_height=     ", orbit_height 
    print*, "payload_mass=     ", payload_mass
    print*, "first_stage_propellant_and_oxidizer= ", first_stage_propellant_and_oxidizer
    print*, "second_stage_propellant_and_oxidizer=", second_stage_propellant_and_oxidizer
    print*, "third_stage_propellant_and_oxidizer= ", third_stage_propellant_and_oxidizer
    print*, "first_stage_combustion_cycle= ", first_stage_combustion_cycle
    print*, "second_stage_combustion_cycle=", second_stage_combustion_cycle
    print*, "third_stage_combustion_cycle= ", third_stage_combustion_cycle
    print*, "diameter_setup = ", diameter_setup
    print*, "user_defined_diameter", user_defined_diameter

    Rocket%number_of_stages = number_of_stages
    allocate(Rocket%stage(number_of_stages))

     select case (first_stage_propellant_and_oxidizer)
    case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX)
        select case (first_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (1) ! 1 - STAGED COMBUSTION 
            First_stage_ISP_lower = 445.6d0
            First_stage_ISP_upper = 454.5d0
            First_stage_ISP_mean  = 451.5d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (2) ! 2 - GAS GENERATOR    
            First_stage_ISP_lower = 405.d0
            First_stage_ISP_upper = 428.1d0
            First_stage_ISP_mean  = 414.367d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (3) ! 3 - EXPANDER
            First_stage_ISP_lower = 425.d0
            First_stage_ISP_upper = 425.d0
            First_stage_ISP_mean  = 425.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown first stage combustion cycle" 
        end select    
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
        select case (first_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (1) ! 1 - STAGED COMBUSTION 
            First_stage_ISP_lower = 337.2d0
            First_stage_ISP_upper = 338.4d0
            First_stage_ISP_mean  = 337.625d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (2) ! 2 - GAS GENERATOR    
            First_stage_ISP_lower = 283.9d0
            First_stage_ISP_upper = 320.2d0
            First_stage_ISP_mean  = 302.625d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown first stage combustion cycle" 
        end select     
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
        select case (first_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (1) ! 1 - STAGED COMBUSTION 
            First_stage_ISP_lower = 350.d0
            First_stage_ISP_upper = 365.d0
            First_stage_ISP_mean  = 357.5d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (2) ! 2 - GAS GENERATOR    
            print*, "WARNING este no es valido"
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown first stage combustion cycle"   
        end select   
    case(4) ! 4 - UDMH/LOX
        select case (first_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (1) ! 1 - STAGED COMBUSTION 
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (2) ! 2 - GAS GENERATOR    
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (3) ! 3 - EXPANDER
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (4) ! 4 - ELECTRIC PUMP
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (5) ! 5 - PRESSURE
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case default
            print*, "WARNING: unknown first stage combustion cycle" 
        end select     
    case(5) ! 5 - UDMH/AK271
        select case (first_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (1) ! 1 - STAGED COMBUSTION 
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (2) ! 2 - GAS GENERATOR    
            First_stage_ISP_lower = 289.d0
            First_stage_ISP_upper = 289.d0
            First_stage_ISP_mean  = 289.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (3) ! 3 - EXPANDER
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (4) ! 4 - ELECTRIC PUMP
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (5) ! 5 - PRESSURE
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case default
            print*, "WARNING: unknown first stage combustion cycle" 
        end select      
    case(6) ! 6 - UDMH/N2O4
        select case (first_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            First_stage_ISP_lower = 315.8d0
            First_stage_ISP_upper = 315.8d0
            First_stage_ISP_mean  = 315.8d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (1) ! 1 - STAGED COMBUSTION 
            First_stage_ISP_lower = 315.8d0
            First_stage_ISP_upper = 315.8d0
            First_stage_ISP_mean  = 315.8d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (2) ! 2 - GAS GENERATOR    
            print*, "WARNING este no es valido"
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown first stage combustion cycle"  
        end select 
    case(7) ! 7 - AEROZINE50/N2O4
        select case (first_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            First_stage_ISP_lower = 0.d0
            First_stage_ISP_upper = 0.d0
            First_stage_ISP_mean  = 0.d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            First_stage_ISP_lower = 296.d0
            First_stage_ISP_upper = 303.9d0
            First_stage_ISP_mean  = 299.95d0

            First_stage_ks_lower = 0.0666d0 
            First_stage_ks_upper = 0.0968d0
            First_stage_ks_mean  = 0.0790d0
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown first stage combustion cycle" 
        end select     
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
           select case (first_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            print*, "WARNING este no es valido"
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            print*, "WARNING este no es valido"
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown first stage combustion cycle"
        end select  
    case default
        print*, "WARNING: unknown first stage propellant and oxidizer"
    end select 

    select case (Second_stage_propellant_and_oxidizer)
    case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX)
        select case (Second_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            Second_stage_ISP_lower = 0.d0
            Second_stage_ISP_upper = 0.d0
            Second_stage_ISP_mean  = 0.d0

            Second_stage_ks_lower = 0.0680d0 
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            Second_stage_ISP_lower = 424.3d0
            Second_stage_ISP_upper = 450.d0
            Second_stage_ISP_mean  = 437.15d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (3) ! 3 - EXPANDER
            Second_stage_ISP_lower = 451.9d0
            Second_stage_ISP_upper = 465.d0
            Second_stage_ISP_mean  = 458.45d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Second stage combustion cycle" 
        end select    
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
        select case (Second_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            Second_stage_ISP_lower = 0.d0
            Second_stage_ISP_upper = 0.d0
            Second_stage_ISP_mean  = 0.d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (1) ! 1 - STAGED COMBUSTION 
            Second_stage_ISP_lower = 346.d0
            Second_stage_ISP_upper = 359.d0
            Second_stage_ISP_mean  = 351.6666667d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (2) ! 2 - GAS GENERATOR    
            Second_stage_ISP_lower = 347.d0
            Second_stage_ISP_upper = 347.d0
            Second_stage_ISP_mean  = 347.d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            Second_stage_ISP_lower = 0.d0
            Second_stage_ISP_upper = 0.d0
            Second_stage_ISP_mean  = 0.d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Second stage combustion cycle" 
        end select     
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
        select case (Second_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            Second_stage_ISP_lower = 354.9439348d0
            Second_stage_ISP_upper = 374.8216106d0
            Second_stage_ISP_mean  = 364.8827727d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (1) ! 1 - STAGED COMBUSTION 
            Second_stage_ISP_lower = 354.9439348d0
            Second_stage_ISP_upper = 374.8216106d0
            Second_stage_ISP_mean  = 364.8827727d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (2) ! 2 - GAS GENERATOR    
            print*, "WARNING este no es valido"
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Second stage combustion cycle"   
        end select   
    case(4) ! 4 - UDMH/LOX
        select case (Second_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            Second_stage_ISP_lower = 360.d0
            Second_stage_ISP_upper = 360.d0
            Second_stage_ISP_mean  = 360.d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            Second_stage_ISP_lower = 360.d0
            Second_stage_ISP_upper = 360.d0
            Second_stage_ISP_mean  = 360.d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Second stage combustion cycle" 
        end select     
    case(5) ! 5 - UDMH/AK271
        select case (Second_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            Second_stage_ISP_lower = 352.1d0
            Second_stage_ISP_upper = 352.1d0
            Second_stage_ISP_mean  = 352.1d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            Second_stage_ISP_lower = 352.1d0
            Second_stage_ISP_upper = 352.1d0
            Second_stage_ISP_mean  = 352.1d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Second stage combustion cycle" 
        end select      
    case(6) ! 6 - UDMH/N2O4
        select case (Second_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            Second_stage_ISP_lower = 327.3d0
            Second_stage_ISP_upper = 327.3d0
            Second_stage_ISP_mean  = 327.3d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            Second_stage_ISP_lower = 327.3d0
            Second_stage_ISP_upper = 327.3d0
            Second_stage_ISP_mean  = 327.3d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Second stage combustion cycle"  
        end select 
    case(7) ! 7 - AEROZINE50/N2O4
        select case (Second_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            Second_stage_ISP_lower = 0.d0
            Second_stage_ISP_upper = 0.d0
            Second_stage_ISP_mean  = 0.d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            Second_stage_ISP_lower = 315.5d0
            Second_stage_ISP_upper = 315.5d0
            Second_stage_ISP_mean  = 315.5d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            Second_stage_ISP_lower = 320.5d0
            Second_stage_ISP_upper = 320.5d0
            Second_stage_ISP_mean  = 320.5d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case default
            print*, "WARNING: unknown Second stage combustion cycle" 
        end select     
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
           select case (Second_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            Second_stage_ISP_lower = 263.d0
            Second_stage_ISP_upper = 263.d0
            Second_stage_ISP_mean  = 263.d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            print*, "WARNING este no es valido"
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            Second_stage_ISP_lower = 263.d0
            Second_stage_ISP_upper = 263.d0
            Second_stage_ISP_mean  = 263.d0

            Second_stage_ks_lower = 0.0680d0  
            Second_stage_ks_upper = 0.1667d0
            Second_stage_ks_mean  = 0.1060d0
        case default
            print*, "WARNING: unknown Second stage combustion cycle"
        end select  
    case default
        print*, "WARNING: unknown Second stage propellant and oxidizer"
    end select 

    select case (Third_stage_propellant_and_oxidizer)
    case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX)
        select case (Third_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            Third_stage_ISP_lower = 0.d0
            Third_stage_ISP_upper = 0.d0
            Third_stage_ISP_mean  = 0.d0

            Third_stage_ks_lower = 0.0744d0
            Third_stage_ks_upper = 0.2193d0
            Third_stage_ks_mean  = 0.1486d0
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            Third_stage_ISP_lower = 420.d0
            Third_stage_ISP_upper = 440.d0
            Third_stage_ISP_mean  = 430.d0

            Third_stage_ks_lower = 0.0744d0 
            Third_stage_ks_upper = 0.2193d0
            Third_stage_ks_mean  = 0.1486d0
        case (3) ! 3 - EXPANDER
            Third_stage_ISP_lower = 406.d0
            Third_stage_ISP_upper = 406.d0
            Third_stage_ISP_mean  = 406.d0

            Third_stage_ks_lower = 0.0744d0 
            Third_stage_ks_upper = 0.2193d0
            Third_stage_ks_mean  = 0.1486d0
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Third stage combustion cycle" 
        end select    
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
        select case (Third_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            Third_stage_ISP_lower = 359.d0
            Third_stage_ISP_upper = 359.d0
            Third_stage_ISP_mean  = 359.d0

            Third_stage_ks_lower = 0.0744d0 
            Third_stage_ks_upper = 0.2193d0
            Third_stage_ks_mean  = 0.1486d0
        case (1) ! 1 - STAGED COMBUSTION 
            Third_stage_ISP_lower = 359.d0
            Third_stage_ISP_upper = 359.d0
            Third_stage_ISP_mean  = 359.d0

            Third_stage_ks_lower = 0.0744d0 
            Third_stage_ks_upper = 0.2193d0
            Third_stage_ks_mean  = 0.1486d0
        case (2) ! 2 - GAS GENERATOR    
            print*, "WARNING este no es valido"
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Third stage combustion cycle" 
        end select     
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
        select case (Third_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            print*, "WARNING este no es valido"
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            print*, "WARNING este no es valido"
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Third stage combustion cycle"   
        end select   
    case(4) ! 4 - UDMH/LOX
        select case (Third_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            print*, "WARNING este no es valido"
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            print*, "WARNING este no es valido"
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Third stage combustion cycle" 
        end select     
    case(5) ! 5 - UDMH/AK271
        select case (Third_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            print*, "WARNING este no es valido"
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            print*, "WARNING este no es valido"
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Third stage combustion cycle" 
        end select      
    case(6) ! 6 - UDMH/N2O4
        select case (Third_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            print*, "WARNING este no es valido"
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            print*, "WARNING este no es valido"
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Third stage combustion cycle"  
        end select 
    case(7) ! 7 - AEROZINE50/N2O4
        select case (Third_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            print*, "WARNING este no es valido"
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            print*, "WARNING este no es valido"
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Third stage combustion cycle" 
        end select     
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
           select case (Third_stage_combustion_cycle)
        case (0) ! 0 - Aproximates engine perfermoance only base on propellant/oxidizer
            print*, "WARNING este no es valido"
        case (1) ! 1 - STAGED COMBUSTION 
            print*, "WARNING este no es valido"
        case (2) ! 2 - GAS GENERATOR    
            print*, "WARNING este no es valido"
        case (3) ! 3 - EXPANDER
            print*, "WARNING este no es valido"
        case (4) ! 4 - ELECTRIC PUMP
            print*, "WARNING este no es valido"
        case (5) ! 5 - PRESSURE
            print*, "WARNING este no es valido"
        case default
            print*, "WARNING: unknown Third stage combustion cycle"
        end select  
    case default
        print*, "WARNING: unknown Third stage propellant and oxidizer"
    end select 
    
    !===== DIAMETER CONFIG CHECK =========
    select case (diameter_setup)
    case(1) 
        print*, "Diameter setup: Statistically Determined"
    case(2)
        print*, "Diameter setup: Constant"
    case(3)
        print*, "Diameter setup: Fairing Requirement"
    case default
        print*, "WARNING: unknown Diameter setup"
        stop
    end select 
    !=====================================

    !============= TEST CASE =============
    !ISP_vector(1) = 400.d0
    !ISP_vector(2) = 350.d0
    !ISP_vector(3) = 300.d0

    !k_s_vector(1) = 0.10d0
    !k_s_vector(2) = 0.15d0
    !k_s_vector(3) = 0.20d0
    !============= Soyuz 2-1v ============
    ISP_vector(1) = 297.d0
    ISP_vector(2) = 359.d0
    ISP_vector(3) = 0.d0

    k_s_vector(1) = 0.0791d0
    k_s_vector(2) = 0.0938d0
    k_s_vector(3) = 0.d0
    !=====================================

   ! ISP_vector(1) = First_stage_ISP_mean
   ! ISP_vector(2) = Second_stage_ISP_mean
   ! ISP_vector(3) = Third_stage_ISP_mean

   ! k_s_vector(1) = First_stage_ks_mean
   ! k_s_vector(2) = Second_stage_ks_mean
   ! k_s_vector(3) = Third_stage_ks_mean

    do i=1, Rocket%number_of_stages
        Rocket%stage(i)%ISP = ISP_vector(i)
        Rocket%stage(i)%k_s = k_s_vector(i)
    end do

    Rocket%ISP_mean = 0.d0
    do i = 1, Rocket%number_of_stages
        Rocket%ISP_mean = Rocket%ISP_mean + Rocket%stage(i)%ISP
    end do
    Rocket%ISP_mean = Rocket%ISP_mean / Rocket%number_of_stages

end subroutine data_entry

subroutine load_config(fname)
    character(len=*), intent(in) :: fname

    character(len=256)            :: line, key, value
    integer :: unit, ios, eqpos
    logical :: exists

    inquire(file=fname, exist=exists)
    if (.not. exists) then
        print *, "ERROR: config file not found:", trim(fname)
        stop
    end if

    open(newunit=unit, file=fname, status='old', action='read', iostat=ios)
    if (ios /= 0) then
        print *, "ERROR opening config.txt file:", trim(fname)
        stop
    end if

    do
        read(unit, '(A)', iostat=ios) line
        if (ios /= 0) exit

        line = adjustl(trim(line))

        if (len_trim(line) == 0) cycle
        if (line(1:1) == '#' .or. line(1:1) == ';') cycle

        eqpos = index(line, " = ")
        if (eqpos == 0) then
            print *, "WARNING: invalid line (without ' = '):", trim(line)
            cycle
        end if

        key   = adjustl(trim(line(1:eqpos-1)))
        value = adjustl(trim(line(eqpos+3:)))

        call to_lower(key)

        select case (key)

        case ("orbit_height")
            read(value, *, iostat=ios) orbit_height
            if (ios /= 0) print *, "WARNING: orbit_height invalid:", value
        
        case ("payload_mass")
            read(value, *, iostat=ios) payload_mass
            if (ios /= 0) print *, "WARNING: payload_mass invalid:", value
        
        case ("number_of_stages")
            read(value, *, iostat=ios) number_of_stages 
            if (ios /= 0) print *, "WARNING: number_of_stages invalid:", value
        
        case ("first_stage_propellant_and_oxidizer")
            read(value, *, iostat=ios) first_stage_propellant_and_oxidizer 
            if (ios /= 0) print *, "WARNING: first_stage_propellant_and_oxidizer invalid:", value
        
        case ("second_stage_propellant_and_oxidizer")
            read(value, *, iostat=ios) second_stage_propellant_and_oxidizer 
            if (ios /= 0) print *, "WARNING: second_stage_propellant_and_oxidizer invalid:", value
        
        case ("third_stage_propellant_and_oxidizer")
            read(value, *, iostat=ios) third_stage_propellant_and_oxidizer 
            if (ios /= 0) print *, "WARNING: third_stage_propellant_and_oxidizer invalid:", value
        
        case ("first_stage_combustion_cycle")
            read(value, *, iostat=ios) first_stage_combustion_cycle 
            if (ios /= 0) print *, "WARNING: first_stage_combustion_cycle invalid:", value

        case ("second_stage_combustion_cycle")
            read(value, *, iostat=ios) first_stage_combustion_cycle 
            if (ios /= 0) print *, "WARNING: first_stage_combustion_cycle invalid:", value

        case ("third_stage_combustion_cycle")
            read(value, *, iostat=ios) first_stage_combustion_cycle 
            if (ios /= 0) print *, "WARNING: first_stage_combustion_cycle invalid:", value

        case ("diameter_setup")
            read(value, *, iostat=ios) diameter_setup
            if (ios /= 0) print *, "WARNING: diameter_setup invalid:", value    
        
        case ("user_defined_diameter")
            read(value, *, iostat=ios) user_defined_diameter
            if (ios /= 0) print *, "WARNING: user_defined_diameter invalid:", value

        case default
            print *, "WARNING: unknown key:", trim(key)

        end select

    end do
    close(unit)
end subroutine load_config

subroutine to_lower(str)
    character(len=*), intent(inout) :: str
    integer :: i
    do i = 1, len_trim(str)
        if (str(i:i) >= 'A' .and. str(i:i) <= 'Z') then
            str(i:i) = achar(iachar(str(i:i)) + 32)
        end if
    end do
end subroutine to_lower
end module typical_data