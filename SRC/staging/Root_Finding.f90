module Root_Finding_Methods
    implicit none
    abstract interface
        function func_interface(x, Rocket) result(value)
            use rocket_types, only: Rocket_t
            implicit none
            real(8), intent(in) :: x
            type(Rocket_t), intent(in) :: Rocket
            real(8) :: value
        end function func_interface
    end interface
contains

function Bolzano_Interval_Start(f, Rocket)
    !This function finds the first finite value of L (not NAN or inf) to use in 
    !the Bolzano root finding method 
    USE, INTRINSIC :: IEEE_ARITHMETIC
    use rocket_types
    implicit none
    procedure(func_interface) :: f
    type(Rocket_t), intent(in) :: Rocket 
    real(8) Bolzano_Interval_Start
    real(8) Left_Bracket    
    integer i

    Left_Bracket = 0.d0 !First aproximation 
    i = 0.d0
    do while (.not. ieee_is_finite(f(Left_Bracket, Rocket)) .and. i<500)
        Left_Bracket = Left_Bracket + 0.01d0
        i = i + 1
    end do 

    if (.not. ieee_is_finite(f(Left_Bracket, Rocket))) print*, "Valid start point not found"
    print*, "Bolzano Interval Start =", Left_Bracket 
    Bolzano_Interval_Start = Left_Bracket 
end function 

subroutine Bolzano_Bisection(f, Rocket, Left_Bracket, Right_Bracket, tol, root, iterations)
    use rocket_types
    procedure(func_interface) :: f
    type(Rocket_t), intent(in)  :: Rocket
    real(8), intent(in)  :: Left_Bracket, Right_Bracket
    real(8), intent(in)  :: tol
    integer, intent(out) :: iterations
    real(8), intent(out) :: root 
    real(8) res 
    real(8) fa, fb, fc                  ! Values of the function at a, b and c 
    real(8) a, b, c
    integer i

    a = Left_Bracket 
    b = Right_Bracket
    c = 0.d0

    ! Bolzano's bisection method 
    i = 0
    res = 1905.d0
    do while (res > tol .and. i < 100)               
        c = (a+b)/2.d0
        fa = f(a, Rocket)
        fb = f(b, Rocket)
        fc = f(c, Rocket)
        print*, c
        if (fa*fc < 0) then 
            b = c
        else if (fb*fc < 0) then
            a = c
        else 
            print*, "Raiz fuera del rango"
        end if 
       ! res = abs(a - b)
        res = abs(f(c, Rocket))     
        i = i + 1
    end do 
    print*, "====================================="
    print*, "iter:  ", i
    print*, "a=     ", a
    print*, "g(a)=  ", f(a, Rocket)
    print*, "b=     ", b
    print*, "g(b)=  ", f(b, Rocket)
    print*, "res=   ", res
    print*, "====================================="

    root = c 
    iterations = i 
  end subroutine Bolzano_Bisection

  subroutine Newton_Raphson(f, Rocket, root, iterations, tol, initial_x0, initial_x1)
    use rocket_types
    implicit none
    procedure(func_interface) :: f
    type(Rocket_t), intent(in) :: Rocket
    real(8), intent(out), optional :: root
    integer, intent(out), optional :: iterations
    real(8), intent(in), optional :: tol
    real(8), intent(in), optional :: initial_x0, initial_x1
    real(8) res, tolerance, denominator
    real(8) X0, X, X1, f0, f_current
    integer i
    integer, parameter :: max_iterations = 100

    ! This routine uses the secant update; it does not calculate a derivative.
    tolerance = 1.d-3
    if (present(tol)) tolerance = tol
    if (tolerance <= 0.d0) error stop "Secant method: tolerance must be positive"
    X0 = 1.d0
    X = 1.5d0
    if (present(initial_x0)) X0 = initial_x0
    if (present(initial_x1)) X = initial_x1
    f0 = f(X0, Rocket)
    f_current = f(X, Rocket)
    res = huge(1.d0)

    do i = 1, max_iterations
        denominator = f_current - f0
        if (abs(denominator) <= tiny(denominator)) error stop "Secant method: zero function-value difference"
        X1 = X - f_current*(X-X0)/denominator
        res = abs(X1-X)
        X0 = X
        f0 = f_current
        X = X1
        f_current = f(X, Rocket)
        if (res <= tolerance) exit
    end do

    if (res > tolerance) error stop "Secant method did not converge"
    if (present(root)) root = X
    if (present(iterations)) iterations = i
  end subroutine Newton_Raphson
end module Root_Finding_Methods