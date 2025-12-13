import { useEffect } from "react";
import { useNavigate } from "react-router-dom";

/**
 * Menu page - redirects to Order page
 * The Order page has the full menu browsing experience with Supabase integration
 */
const Menu = () => {
  const navigate = useNavigate();

  useEffect(() => {
    // Redirect to the order page which has the proper menu implementation
    navigate("/order", { replace: true });
  }, [navigate]);

  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        <p className="mt-4 text-muted-foreground">Loading menu...</p>
      </div>
    </div>
  );
};

export default Menu;
