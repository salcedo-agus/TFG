module rocket_types
    implicit none
    type Tank_t
        real(8) m_liq ! Fuel or oxidizer mass
        
        real(8) v_ulage       ! Ulage volume needed for pressurizing the tank
        real(8) v_contraction ! Contraction volume for cryogenic liquids
        
        real(8) dome_AR       ! Dome aspect ratio
        real(8) h_cyl         ! Cylinder height

        real(8) m_shell       ! Tank mass
        real(8) m_insulation  ! Insulation mas for cryogenic liquids
    end type Tank_t

    type Stage_t
        real(8) m_0    ! Initial mass of the partial rocket
        real(8) m_i    ! Initial mass of the stage
        real(8) m_f    ! Final or Empty mass of the partial rocket 
        real(8) m_L    ! Payload mass of the stage 
        real(8) m_s    ! Structure mass of the stage
        real(8) m_p    ! Usable propelant mass of the stage

        real(8) m_p_total     ! Includes propelant masses not available for propulsion
        real(8) m_p_start_up  ! Propelant mass used for engine Start-Up
        real(8) m_p_aditional ! Residual propelant mass, left in the tanks at engine cut-off 
        real(8) m_wiring      ! Wiring mass
        real(8) m_engines     ! Engines mass
        real(8) m_avionics    ! Avionics mass
        real(8) m_unpr_str    ! Mass of unpresurized structure

        real(8) k_m    ! Mass ratio
        real(8) k_s    ! Structural ratio
        real(8) k_L    ! Payload ratio
        
        real(8) ISP    ! Specific impulse
        real(8) T      ! Stage thrust
        real(8) m_dot  ! Stage mass flow
        real(8) t_burn ! Stage burn time
        real(8) D_v    ! Delta_v provided by the stage 
        real(8) nu_e   ! Effective escape velocity 

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

        real(8) rt_burn  !Rocket burn time (ascent time)
        real(8) ISP_mean    !Rocket mean ISP
        real(8) delta_v
        real(8) DV_loss
        real(8) nu_e_mean   !Rocket mean exhaust velocity

    end type Rocket_t  
end module 
