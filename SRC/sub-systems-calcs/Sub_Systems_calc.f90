subroutine m_p_total_calc(Rocket)
    use rocket_types
    use typical_data
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    real(8), parameter :: t_start_up = 1.d0     !t_start_up fijo en 1 segundo
    real(8), parameter :: f_residual = 0.0125d0     !f_residual fijo en 1.25%
    integer i

!==================== m_p_total calculation according to section 4 ===============================    
    do i=1, number_of_stages
        rocket%stage(i)%m_p_start_up = rocket%stage(i)%m_dot * t_start_up
        rocket%stage(i)%m_p_aditional = (rocket%stage(i)%m_p + rocket%stage(i)%m_p_start_up) * f_residual   !tengo en cuenta para la m_p_aditional tanto la masa de propulsion como la de startup
        rocket%stage(i)%m_p_total = rocket%stage(i)%m_p_start_up + rocket%stage(i)%m_p_aditional
    end do

end subroutine m_p_total_calc



!subroutine MERS_Calc
 !   use rocket_types
  !  use typical_data
   ! implicit none
    !type(Rocket_t), intent(inout) :: Rocket

!    rocket%stage(i)%m_unpr_str =

 !   do i=1, number_of_stages
         
  !  end do
!end subroutine MERS_Calc