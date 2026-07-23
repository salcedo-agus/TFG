module rocket_types
    implicit none
    type Stage_t
        real(8) m_0    ! Initial mass of the partial rocket
        real(8) m_f    ! Final or Empty mass of the partial rocket 
        real(8) m_L    ! Payload mass of the stage 
        real(8) m_s    ! Structure mass of the stage
        real(8) m_p    ! Propelant mass of the stage
        
        real(8) k_m    ! Mass ratio
        real(8) k_s    ! Structural ratio
        real(8) k_L    ! Payload ratio
        
        real(8) ISP    ! Specific impulse
        real(8) T      ! Stage thrust
        real(8) m_dot  ! Stage mass flow
        real(8) t_burn ! Stage burn time
        real(8) D_v    ! Delta_v provided by the stage 
        real(8) nu_e   ! Effective escape velocity 
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
        
    end type Rocket_t  
end module 
