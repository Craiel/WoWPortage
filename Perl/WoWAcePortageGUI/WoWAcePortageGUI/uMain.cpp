/*



*/

#include <gtk/gtk.h>
#define WINDOWS

#ifdef WINDOWS
  #include <windows.h>
#endif

static gboolean delete_event( GtkWidget *widget, GdkEvent  *event, gpointer   data )
{
    return false;
}

static void destroy( GtkWidget *widget,
                     gpointer   data )
{
    gtk_main_quit ();
}

enum
{
  COL_CB  = 0,
  COL_NAME,
  COL_AGE,
  NUM_COLS
} ;

static GtkTreeModel *
create_and_fill_model (void)
{
  GtkListStore  *store;
  GtkTreeIter    iter;
  
  store = gtk_list_store_new (NUM_COLS, G_TYPE_STRING, G_TYPE_UINT);

  /* Append a row and fill in some data */
  gtk_list_store_append (store, &iter);
  gtk_list_store_set (store, &iter,
                      COL_NAME, "Heinz El-Mann",
                      COL_AGE, 51,
                      -1);
  
  /* append another row and fill in some data */
  gtk_list_store_append (store, &iter);
  gtk_list_store_set (store, &iter,
                      COL_NAME, "Jane Doe",
                      COL_AGE, 23,
                      -1);
  
  /* ... and a third row */
  gtk_list_store_append (store, &iter);
  gtk_list_store_set (store, &iter,
                      COL_NAME, "Joe Bungop",
                      COL_AGE, 91,
                      -1);
  
  return GTK_TREE_MODEL (store);
}

static GtkWidget *
create_view_and_model (void)
{
  GtkCellRenderer     *renderer;
  GtkTreeModel        *model;
  GtkWidget           *view;

  view = gtk_tree_view_new ();

  renderer = gtk_cell_renderer_text_new ();
  gtk_tree_view_insert_column_with_attributes (GTK_TREE_VIEW (view),
                                               -1,      
                                               "CB",  
                                               renderer,
                                               "text", COL_CB,
                                               NULL);

  /* --- Column #1 --- */

  renderer = gtk_cell_renderer_text_new ();
  gtk_tree_view_insert_column_with_attributes (GTK_TREE_VIEW (view),
                                               -1,      
                                               "Name",  
                                               renderer,
                                               "text", COL_NAME,
                                               NULL);

  /* --- Column #2 --- */

  renderer = gtk_cell_renderer_text_new ();
  gtk_tree_view_insert_column_with_attributes (GTK_TREE_VIEW (view),
                                               -1,      
                                               "Age",  
                                               renderer,
                                               "text", COL_AGE,
                                               NULL);

  model = create_and_fill_model ();

  gtk_tree_view_set_model (GTK_TREE_VIEW (view), model);

  /* The tree view has acquired its own reference to the
   *  model, so we can drop ours. That way the model will
   *  be freed automatically when the tree view is destroyed */

  g_object_unref (model);

  return view;
}

#ifdef WINDOWS
  int WINAPI WinMain(HINSTANCE Inst, HINSTANCE PrevInst, LPSTR CmdLine, int ShowCmd)
#else
  int main( int   argc, char *argv[] )
#endif
{

    /* GtkWidget is the storage type for widgets */
    GtkWidget *window;
    GtkWidget *list;
    
#ifdef WINDOWS
    gtk_init (0, NULL);
#else
	gtk_init (&argc, &argv);
#endif
    
    window = gtk_window_new (GTK_WINDOW_TOPLEVEL);    

    g_signal_connect (G_OBJECT (window), "delete_event", G_CALLBACK (delete_event), NULL);    
    g_signal_connect (G_OBJECT (window), "destroy", G_CALLBACK (destroy), NULL);    
    gtk_container_set_border_width (GTK_CONTAINER (window), 10);
    

    /* Creates a new button with the label "Hello World". */
    list = create_view_and_model ();

    gtk_container_add (GTK_CONTAINER (window), list);    
    gtk_widget_show (list);
    gtk_widget_show (window);
    
    gtk_main ();

	return 0;
}