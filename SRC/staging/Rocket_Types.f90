module rocket_types
    implicit none
    type Tank_t
        real(8) m_liq   ! [kg] Fuel or oxidizer mass
        real(8) rho_liq ! [kg/m^3] Fuel or oxidizer density
        real(8) v_liq   ! [m^3] Fuel or oxidizer volume
        
        real(8) v_ullage      ! [m^3] Ulage volume needed for pressurizing the tank
        real(8) v_contraction ! [m^3] Contraction volume for cryogenic liquids
        real(8) v_total       ! [m^3] Total necessary tank volume
        real(8) dome_AR       ! Dome aspect ratio
        real(8) h_cyl         ! [m] Cylinder height
        real(8) Surface       ! [m^2] Tank surface area

        real(8) k_shell       ! [kg/m^3] Meassures the amount of insulaton mass per tank volume
        real(8) m_shell       ! [kg] Tank mass
        real(8) k_insulation  ! [kg/m^2] Meassures the amount of insulaton mass per tank surface aera
        real(8) m_insulation  ! [kg] Insulation mass for cryogenic liquids
    end type Tank_t

    type Stage_t
        real(8) m_0           ! [kg] Initial mass of the partial rocket
        real(8) m_i           ! [kg] Initial mass of the stage
        real(8) m_f           ! [kg] Final or Empty mass of the partial rocket 
        real(8) m_L           ! [kg] Payload mass of the stage 
        real(8) m_s           ! [kg] Structure mass of the stage
        real(8) m_p           ! [kg] Usable propelant mass of the stage

        real(8) f_fuel_oxi    ! Fuel/Oxidizer mix ratio
        real(8) m_p_total     ! [kg] Includes propelant masses not available for propulsion
        real(8) m_p_start_up  ! [kg] Propelant mass used for engine Start-Up
        real(8) m_p_aditional ! [kg] Residual propelant mass, left in the tanks at engine cut-off 
        real(8) m_wiring      ! [kg] Wiring mass
        real(8) m_engines     ! [kg] Engines mass
        real(8) m_avionics    ! [kg] Avionics mass
        real(8) bulk_density

        real(8) m_unpr_str    ! Mass of unpresurized structure

        type(Tank_t), dimension(2) :: Tank ! Proppelant tanks; 1 = fuel tank | 2 = oxidizer tank

        real(8) k_m    ! Mass ratio
        real(8) k_s    ! Structural ratio
        real(8) k_L    ! Payload ratio
        
        real(8) ISP    ! [] Specific impulse
        real(8) T      ! [N] Stage thrust
        real(8) m_dot  ! [kg/s] Stage mass flow
        real(8) t_burn ! [s] Stage burn time
        real(8) D_v    ! [km/s] Delta_v provided by the stage 
        real(8) nu_e   ! [km/s] Effective escape velocity 

        real(8) Diameter
        real(8) Length
    end type Stage_t 

    type Rocket_t
        integer number_of_stages
        type(Stage_t), allocatable :: stage(:)
        real(8) rm_0  ! Initial mass of the Rocket                
        real(8) rm_f  ! Final or Empty mass of the Rokcet
        real(8) rm_L  ! Payload mass of the Rocket
        real(8) rm_s  ! Structure mass of the Rocket
        real(8) rm_p  ! Propelant mass of the Rocket
        
        real(8) rk_m  ! Mass ratio
        real(8) rk_s  ! Structural ratio
        real(8) rk_L  ! Payload ratio

        real(8) rt_burn     ! Rocket burn time (ascent time)
        real(8) ISP_mean    ! Rocket mean ISP
        real(8) delta_v     ! [km/s]
        real(8) DV_loss     ! [km/s]
        real(8) nu_e_mean   ! Rocket mean exhaust velocity

    end type Rocket_t  
end module 
