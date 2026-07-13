subroutine STAGING_LOOP(Rocket)
    use typical_data
    use rocket_types
    use constants
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    real(8) DV_old, DV_new !old and new Delta_v iterations
    real(8) err            !difference between 2 iterations of Delta_v
    
    err=1
    DV_old = 0.d0
    DV_new = 0.d0
    do while(err > 1e-3)

        call STAGING(Rocket)    
      ! call DV_loss(Rocket)   
        err = abs(DV_old - DV_new)
    end do
end subroutine STAGING_LOOP

