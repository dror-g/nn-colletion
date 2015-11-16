/************************************************************************
 * optdialog.c    Configuration file editing dialog                     *
 * Copyright (C)  2002-2004  Ben Webb                                   *
 *                Email: benwebb@users.sf.net                           *
 *                WWW: http://dopewars.sourceforge.net/                 *
 *                                                                      *
 * This program is free software; you can redistribute it and/or        *
 * modify it under the terms of the GNU General Public License          *
 * as published by the Free Software Foundation; either version 2       *
 * of the License, or (at your option) any later version.               *
 *                                                                      *
 * This program is distributed in the hope that it will be useful,      *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of       *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        *
 * GNU General Public License for more details.                         *
 *                                                                      *
 * You should have received a copy of the GNU General Public License    *
 * along with this program; if not, write to the Free Software          *
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston,               *
 *                   MA  02111-1307, USA.                               *
 ************************************************************************/

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>             /* For strcmp */
#include <stdlib.h>             /* For atoi */

#include "configfile.h"         /* For UpdateConfigFile etc. */
#include "dopewars.h"           /* For struct GLOBALS etc. */
#include "gtk_client.h"         /* For mainwindow etc. */
#include "nls.h"                /* For _ function */
#include "sound.h"              /* For SoundPlay */
#include "gtkport/gtkport.h"    /* For gtk_ functions */

struct ConfigWidget {
  GtkWidget *widget;
  gint globind;
  int maxindex;
  gchar **data;
};

static GSList *configlist = NULL, *clists = NULL;

struct ConfigMembers {
  gchar *label, *name;
};

static void FreeConfigWidgets(void)
{
  while (configlist) {
    int i;
    struct ConfigWidget *cwid = (struct ConfigWidget *)configlist->data;

    for (i = 0; i < cwid->maxindex; i++) {
      g_free(cwid->data[i]);
    }
    g_free(cwid->data);
    configlist = g_slist_remove(configlist, cwid);
  }
}

static void UpdateAllLists(void)
{
  GSList *listpt;

  for (listpt = clists; listpt; listpt = g_slist_next(listpt)) {
    GtkCList *clist = GTK_CLIST(listpt->data);

    if (clist->selection) {
      int row = GPOINTER_TO_INT(clist->selection->data);

      if (row >= 0) {
        gtk_clist_unselect_row(clist, row, 0);
      }
    }
  }
}

static void SaveConfigWidget(struct GLOBALS *gvar, struct ConfigWidget *cwid,
                             int structind)
{
  gboolean changed = FALSE;

  if (gvar->BoolVal) {
    gboolean *boolpt, newset;

    boolpt = GetGlobalBoolean(cwid->globind, structind);
    if (cwid->maxindex) {
      newset = (cwid->data[structind - 1] != NULL);
    } else {
      newset = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(cwid->widget));
    }
    changed = (*boolpt != newset);
    *boolpt = newset;
  } else {
    gchar *text;

    if (cwid->maxindex) {
      text = cwid->data[structind - 1];
    } else {
      text = gtk_editable_get_chars(GTK_EDITABLE(cwid->widget), 0, -1);
    }
    if (gvar->IntVal) {
      int *intpt, newset;

      intpt = GetGlobalInt(cwid->globind, structind);
      newset = atoi(text);
      if (newset < gvar->MinVal) {
        newset = gvar->MinVal;
      }
      if (gvar->MaxVal > gvar->MinVal && newset > gvar->MaxVal) {
        newset = gvar->MaxVal;
      }
      changed = (*intpt != newset);
      *intpt = newset;
    } else if (gvar->PriceVal) {
      price_t *pricept, newset;

      pricept = GetGlobalPrice(cwid->globind, structind);
      newset = strtoprice(text);
      changed = (*pricept != newset);
      *pricept = newset;
    } else if (gvar->StringVal) {
      gchar **strpt;

      strpt = GetGlobalString(cwid->globind, structind);
      changed = (strcmp(*strpt, text) != 0);
      AssignName(strpt, text);
    }
    if (!cwid->maxindex) {
      g_free(text);
    }
  }
  gvar->Modified |= changed;
}

static void ResizeList(struct GLOBALS *gvar, int newmax)
{
  int i;

  for (i = 0; i < NUMGLOB; i++) {
    if (Globals[i].StructListPt == gvar->StructListPt
        && Globals[i].ResizeFunc) {
      Globals[i].Modified = TRUE;
      (Globals[i].ResizeFunc) (newmax);
      return;
    }
  }
  g_assert(0);
}

static void SaveConfigWidgets(void)
{
  GSList *listpt;

  UpdateAllLists();

  for (listpt = configlist; listpt; listpt = g_slist_next(listpt)) {
    struct ConfigWidget *cwid = (struct ConfigWidget *)listpt->data;
    struct GLOBALS *gvar;

    gvar = &Globals[cwid->globind];
    if (gvar->NameStruct && gvar->NameStruct[0]) {
      int i;

      if (cwid->maxindex != *gvar->MaxIndex) {
        ResizeList(gvar, cwid->maxindex);
      }

      for (i = 1; i <= *gvar->MaxIndex; i++) {
        SaveConfigWidget(gvar, cwid, i);
      }
    } else {
      SaveConfigWidget(gvar, cwid, 0);
    }
  }
}

static void AddConfigWidget(GtkWidget *widget, int ind)
{
  struct ConfigWidget *cwid = g_new(struct ConfigWidget, 1);
  struct GLOBALS *gvar;
  
  cwid->widget = widget;
  cwid->globind = ind;
  cwid->data = NULL;
  cwid->maxindex = 0;

  gvar = &Globals[ind];
  if (gvar->MaxIndex) {
    int i;

    cwid->maxindex = *gvar->MaxIndex;
    cwid->data = g_new(gchar *, *gvar->MaxIndex);
    for (i = 1; i <= *gvar->MaxIndex; i++) {
      if (gvar->StringVal) {
        cwid->data[i - 1] = g_strdup(*GetGlobalString(ind, i));
      } else if (gvar->IntVal) {
        cwid->data[i - 1] =
            g_strdup_printf("%d", *GetGlobalInt(ind, i));
      } else if (gvar->PriceVal) {
        cwid->data[i - 1] = pricetostr(*GetGlobalPrice(ind, i));
      } else if (gvar->BoolVal) {
        if (*GetGlobalBoolean(ind, i)) {
          cwid->data[i - 1] = g_strdup("1");
        } else {
          cwid->data[i - 1] = NULL;
        }
      }
    }
  }
  configlist = g_slist_append(configlist, cwid);
}

static GtkWidget *NewConfigCheck(gchar *name, gchar *label)
{
  GtkWidget *check;
  int ind;
  struct GLOBALS *gvar;

  ind = GetGlobalIndex(name, NULL);
  g_assert(ind >= 0);
  gvar = &Globals[ind];
  g_assert(gvar->BoolVal);

  check = gtk_check_button_new_with_label(label);
  gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(check), *gvar->BoolVal);

  AddConfigWidget(check, ind);

  return check;
}

static GtkWidget *NewConfigEntry(gchar *name)
{
  GtkWidget *entry;
  gchar *tmpstr;
  int ind;
  struct GLOBALS *gvar;

  ind = GetGlobalIndex(name, NULL);
  g_assert(ind >= 0);

  entry = gtk_entry_new();
  gvar = &Globals[ind];

  if (gvar->StringVal) {
    gtk_entry_set_text(GTK_ENTRY(entry), *gvar->StringVal);
  } else if (gvar->IntVal) {
    if (gvar->MaxVal > gvar->MinVal) {
      GtkAdjustment *spin_adj;

      gtk_widget_destroy(entry);
      spin_adj = (GtkAdjustment *)gtk_adjustment_new(*gvar->IntVal,
                                                     gvar->MinVal,
                                                     gvar->MaxVal,
                                                     1.0, 10.0, 10.0);
      entry = gtk_spin_button_new(spin_adj, 1.0, 0);
    } else {
      tmpstr = g_strdup_printf("%d", *gvar->IntVal);
      gtk_entry_set_text(GTK_ENTRY(entry), tmpstr);
      g_free(tmpstr);
    }
  } else if (gvar->PriceVal) {
    tmpstr = pricetostr(*gvar->PriceVal);
    gtk_entry_set_text(GTK_ENTRY(entry), tmpstr);
    g_free(tmpstr);
  }

  AddConfigWidget(entry, ind);

  return entry;
}

static void AddStructConfig(GtkWidget *table, int row, gchar *structname,
                            struct ConfigMembers *member)
{
  int ind;
  struct GLOBALS *gvar;

  ind = GetGlobalIndex(structname, member->name);
  g_assert(ind >= 0);

  gvar = &Globals[ind];
  if (gvar->BoolVal) {
    GtkWidget *check;

    check = gtk_check_button_new_with_label(_(member->label));
    gtk_table_attach_defaults(GTK_TABLE(table), check, 0, 2, row, row + 1);
    AddConfigWidget(check, ind);
  } else {
    GtkWidget *label, *entry;

    label = gtk_label_new(_(member->label));
    gtk_table_attach(GTK_TABLE(table), label, 0, 1, row, row + 1,
                     GTK_SHRINK, GTK_SHRINK, 0, 0);
    if (gvar->IntVal && gvar->MaxVal > gvar->MinVal) {
      GtkAdjustment *spin_adj = (GtkAdjustment *)
          gtk_adjustment_new(gvar->MinVal, gvar->MinVal, gvar->MaxVal,
                             1.0, 10.0, 10.0);
      entry = gtk_spin_button_new(spin_adj, 1.0, 0);
    } else {
      entry = gtk_entry_new();
    }
    gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 2, row, row + 1);
    AddConfigWidget(entry, ind);
  }
}

static void swap_rows(GtkCList *clist, gint selrow, gint swaprow,
                      gchar *structname)
{
  GSList *listpt;

  gtk_clist_unselect_row(clist, selrow, 0);

  for (listpt = configlist; listpt; listpt = g_slist_next(listpt)) {
    struct ConfigWidget *cwid = (struct ConfigWidget *)listpt->data;
    struct GLOBALS *gvar;

    gvar = &Globals[cwid->globind];

    if (gvar->NameStruct && strcmp(structname, gvar->NameStruct) == 0) {
      gchar *tmp = cwid->data[selrow];

      cwid->data[selrow] = cwid->data[swaprow];
      cwid->data[swaprow] = tmp;
      if (strcmp(gvar->Name, "Name") == 0) {
        gtk_clist_set_text(clist, selrow, 0, cwid->data[selrow]);
        gtk_clist_set_text(clist, swaprow, 0, cwid->data[swaprow]);
      }
    }
  }

  gtk_clist_select_row(clist, swaprow, 0);
}

static void list_delete(GtkWidget *widget, gchar *structname)
{
  GtkCList *clist;
  int minlistlength;

  clist = GTK_CLIST(gtk_object_get_data(GTK_OBJECT(widget), "clist"));
  g_assert(clist);
  minlistlength = GPOINTER_TO_INT(gtk_object_get_data(GTK_OBJECT(clist),
                                                      "minlistlength"));

  if (clist->rows > minlistlength && clist->selection) {
    GSList *listpt;
    int row = GPOINTER_TO_INT(clist->selection->data);

    gtk_clist_remove(clist, row);
    for (listpt = configlist; listpt; listpt = g_slist_next(listpt)) {
      struct ConfigWidget *cwid = (struct ConfigWidget *)listpt->data;
      struct GLOBALS *gvar;

      gvar = &Globals[cwid->globind];
      if (gvar->NameStruct && strcmp(structname, gvar->NameStruct) == 0) {
        int i;

        cwid->maxindex--;
        g_free(cwid->data[row]);
        for (i = row; i < cwid->maxindex; i++) {
          cwid->data[i] = cwid->data[i + 1];
        }
        cwid->data = g_realloc(cwid->data, sizeof(gchar *) * cwid->maxindex);
      }
    }
  }
}

static void list_new(GtkWidget *widget, gchar *structname)
{
  GtkCList *clist;
  int row;
  GSList *listpt;
  gchar *text[3];

  clist = GTK_CLIST(gtk_object_get_data(GTK_OBJECT(widget), "clist"));
  g_assert(clist);

  text[0] = g_strdup_printf(_("New %s"), structname);
  row = gtk_clist_append(clist, text);

  for (listpt = configlist; listpt; listpt = g_slist_next(listpt)) {
    struct ConfigWidget *cwid = (struct ConfigWidget *)listpt->data;
    struct GLOBALS *gvar;

    gvar = &Globals[cwid->globind];
    if (gvar->NameStruct && strcmp(structname, gvar->NameStruct) == 0) {
      cwid->maxindex++;
      g_assert(cwid->maxindex == row + 1);
      cwid->data = g_realloc(cwid->data, sizeof(gchar *) * cwid->maxindex);
      if (strcmp(gvar->Name, "Name") == 0) {
        cwid->data[row] = g_strdup(text[0]);
      } else {
        cwid->data[row] = g_strdup("");
      }
    }
  }
  g_free(text[0]);

  gtk_clist_select_row(clist, row, 0);
}

static void list_up(GtkWidget *widget, gchar *structname)
{
  GtkCList *clist;

  clist = GTK_CLIST(gtk_object_get_data(GTK_OBJECT(widget), "clist"));
  g_assert(clist);

  if (clist->selection) {
    int row = GPOINTER_TO_INT(clist->selection->data);

    if (row > 0) {
      swap_rows(clist, row, row - 1, structname);
    }
  }
}

static void list_down(GtkWidget *widget, gchar *structname)
{
  GtkCList *clist;

  clist = GTK_CLIST(gtk_object_get_data(GTK_OBJECT(widget), "clist"));
  g_assert(clist);

  if (clist->selection) {
    int row = GPOINTER_TO_INT(clist->selection->data);
    int numrows = clist->rows;

    if (row < numrows - 1 && row >= 0) {
      swap_rows(clist, row, row + 1, structname);
    }
  }
}

static void list_row_select(GtkCList *clist, gint row, gint column,
                            GdkEvent *event, gchar *structname)
{
  GSList *listpt;
  GtkWidget *delbut, *upbut, *downbut;
  int minlistlength;

  minlistlength = GPOINTER_TO_INT(gtk_object_get_data(GTK_OBJECT(clist),
                                                      "minlistlength"));
  delbut  = GTK_WIDGET(gtk_object_get_data(GTK_OBJECT(clist), "delete"));
  upbut   = GTK_WIDGET(gtk_object_get_data(GTK_OBJECT(clist), "up"));
  downbut = GTK_WIDGET(gtk_object_get_data(GTK_OBJECT(clist), "down"));
  g_assert(delbut && upbut && downbut);
  gtk_widget_set_sensitive(delbut, clist->rows > minlistlength);
  gtk_widget_set_sensitive(upbut, row > 0);
  gtk_widget_set_sensitive(downbut, row < clist->rows - 1);

  for (listpt = configlist; listpt; listpt = g_slist_next(listpt)) {
    struct ConfigWidget *conf = (struct ConfigWidget *)listpt->data;
    struct GLOBALS *gvar;

    gvar = &Globals[conf->globind];

    if (gvar->NameStruct && strcmp(structname, gvar->NameStruct) == 0) {
      if (gvar->BoolVal) {
        gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(conf->widget),
                                     conf->data[row] != NULL);
      } else {
        gtk_entry_set_text(GTK_ENTRY(conf->widget), conf->data[row]);
      }
    }
  }
}

static void list_row_unselect(GtkCList *clist, gint row, gint column,
                              GdkEvent *event, gchar *structname)
{
  GSList *listpt;
  GtkWidget *delbut, *upbut, *downbut;

  delbut  = GTK_WIDGET(gtk_object_get_data(GTK_OBJECT(clist), "delete"));
  upbut   = GTK_WIDGET(gtk_object_get_data(GTK_OBJECT(clist), "up"));
  downbut = GTK_WIDGET(gtk_object_get_data(GTK_OBJECT(clist), "down"));
  g_assert(delbut && upbut && downbut);
  gtk_widget_set_sensitive(delbut, FALSE);
  gtk_widget_set_sensitive(upbut, FALSE);
  gtk_widget_set_sensitive(downbut, FALSE);


  for (listpt = configlist; listpt; listpt = g_slist_next(listpt)) {
    struct ConfigWidget *conf = (struct ConfigWidget *)listpt->data;
    struct GLOBALS *gvar;

    gvar = &Globals[conf->globind];

    if (gvar->NameStruct && strcmp(structname, gvar->NameStruct) == 0) {
      g_free(conf->data[row]);
      conf->data[row] = NULL;

      if (gvar->BoolVal) {
        if (gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(conf->widget))) {
          conf->data[row] = g_strdup("1");
        }
      } else {
        conf->data[row] = gtk_editable_get_chars(GTK_EDITABLE(conf->widget),
                                                 0, -1);
        gtk_entry_set_text(GTK_ENTRY(conf->widget), "");
      }
      if (strcmp(gvar->Name, "Name") == 0) {
        gtk_clist_set_text(clist, row, 0, conf->data[row]);
      }
    }
  }
}

static void sound_row_select(GtkCList *clist, gint row, gint column,
                             GdkEvent *event, gpointer data)
{
  GtkWidget *entry;
  int globind;
  gchar **text;

  entry = GTK_WIDGET(gtk_object_get_data(GTK_OBJECT(clist), "entry"));
  globind = GPOINTER_TO_INT(gtk_clist_get_row_data(clist, row));
  g_assert(globind >=0 && globind < NUMGLOB);

  text = GetGlobalString(globind, 0);
  gtk_entry_set_text(GTK_ENTRY(entry), *text);
}

static void sound_row_unselect(GtkCList *clist, gint row, gint column,
                               GdkEvent *event, gpointer data)
{
  GtkWidget *entry;
  int globind;
  gchar *text, **oldtext;

  entry = GTK_WIDGET(gtk_object_get_data(GTK_OBJECT(clist), "entry"));
  globind = GPOINTER_TO_INT(gtk_clist_get_row_data(clist, row));
  g_assert(globind >=0 && globind < NUMGLOB);

  text = gtk_editable_get_chars(GTK_EDITABLE(entry), 0, -1);
  oldtext = GetGlobalString(globind, 0);
  g_assert(text && oldtext);
  if (strcmp(text, *oldtext) != 0) {
    AssignName(GetGlobalString(globind, 0), text);
    Globals[globind].Modified = TRUE;
  }
  gtk_entry_set_text(GTK_ENTRY(entry), "");
  g_free(text);
}

static void BrowseSound(GtkWidget *entry)
{
  gchar *oldtext, *newtext;
  GtkWidget *dialog = gtk_widget_get_ancestor(entry, GTK_TYPE_WINDOW);

  oldtext = gtk_editable_get_chars(GTK_EDITABLE(entry), 0, -1);

  newtext = GtkGetFile(dialog, oldtext, _("Select sound file"));
  g_free(oldtext);
  if (newtext) {
    gtk_entry_set_text(GTK_ENTRY(entry), newtext);
    g_free(newtext);
  }
}

static void TestPlaySound(GtkWidget *entry)
{
  gchar *text;
  gboolean sound_enabled;

  text = gtk_editable_get_chars(GTK_EDITABLE(entry), 0, -1);
  sound_enabled = IsSoundEnabled();
  SoundEnable(TRUE);
  SoundPlay(text);
  SoundEnable(sound_enabled);
  g_free(text);
}

static void OKCallback(GtkWidget *widget, GtkWidget *dialog)
{
  GtkToggleButton *unicode_check;

  SaveConfigWidgets();
  unicode_check = GTK_TOGGLE_BUTTON(gtk_object_get_data(GTK_OBJECT(dialog),
                                                        "unicode_check"));
  UpdateConfigFile(NULL, gtk_toggle_button_get_active(unicode_check));
  gtk_widget_destroy(dialog);
}

static gchar *GetHelpPage(const gchar *pagename)
{
  gchar *root, *file;

  root = GetDocRoot();
  file = g_strdup_printf("%shelp%c%s.html", root, G_DIR_SEPARATOR, pagename);
  g_free(root);
  return file;
}

static void HelpCallback(GtkWidget *widget, GtkWidget *notebook)
{
  const static gchar *pagehelp[] = {
    "general", "locations", "drugs", "guns", "cops", "server", "sounds"
  };
  gint page = gtk_notebook_get_current_page(GTK_NOTEBOOK(notebook));
  gchar *help;

  help = GetHelpPage(pagehelp[page]);
  DisplayHTML(widget, WebBrowser, help);
  g_free(help);
}

static void FinishOptDialog(GtkWidget *widget, gpointer data)
{
  FreeConfigWidgets();

  g_slist_free(clists);
  clists = NULL;
}

static GtkWidget *CreateList(gchar *structname, struct ConfigMembers *members)
{
  GtkWidget *hbox, *vbox, *hbbox, *clist, *scrollwin, *button, *table;
  gchar *titles[3];
  int ind, minlistlength = 0;
  gint i, row, nummembers;
  struct GLOBALS *gvar;
  struct ConfigMembers namemember = { N_("Name"), "Name" };

  ind = GetGlobalIndex(structname, "Name");
  g_assert(ind >= 0);
  gvar = &Globals[ind];
  g_assert(gvar->StringVal && gvar->MaxIndex);

  for (i = 0; i < NUMGLOB; i++) {
    if (Globals[i].StructListPt == gvar->StructListPt
        && Globals[i].ResizeFunc) {
      minlistlength = Globals[i].MinVal;
    }
  }

  nummembers = 0;
  while (members && members[nummembers].label) {
    nummembers++;
  }

  hbox = gtk_hbox_new(FALSE, 10);

  vbox = gtk_vbox_new(FALSE, 5);

  titles[0] = structname;
  clist = gtk_scrolled_clist_new_with_titles(1, titles, &scrollwin);

  gtk_signal_connect(GTK_OBJECT(clist), "select_row",
                     GTK_SIGNAL_FUNC(list_row_select), structname);
  gtk_signal_connect(GTK_OBJECT(clist), "unselect_row",
                     GTK_SIGNAL_FUNC(list_row_unselect), structname);
  gtk_clist_column_titles_passive(GTK_CLIST(clist));
  gtk_clist_set_selection_mode(GTK_CLIST(clist), GTK_SELECTION_SINGLE);
  gtk_clist_set_auto_sort(GTK_CLIST(clist), FALSE);

  clists = g_slist_append(clists, clist);

  for (i = 1; i <= *gvar->MaxIndex; i++) {
    titles[0] = *GetGlobalString(ind, i);
    row = gtk_clist_append(GTK_CLIST(clist), titles);
  }
  gtk_box_pack_start(GTK_BOX(vbox), scrollwin, TRUE, TRUE, 0);

  hbbox = gtk_hbox_new(TRUE, 5);

  button = gtk_button_new_with_label(_("New"));
  gtk_object_set_data(GTK_OBJECT(button), "clist", clist);
  gtk_signal_connect(GTK_OBJECT(button), "clicked",
                     GTK_SIGNAL_FUNC(list_new), structname);
  gtk_box_pack_start(GTK_BOX(hbbox), button, TRUE, TRUE, 0);

  button = gtk_button_new_with_label(_("Delete"));
  gtk_widget_set_sensitive(button, FALSE);
  gtk_object_set_data(GTK_OBJECT(button), "clist", clist);
  gtk_object_set_data(GTK_OBJECT(clist), "delete", button);
  gtk_object_set_data(GTK_OBJECT(clist), "minlistlength",
                      GINT_TO_POINTER(minlistlength));
  gtk_signal_connect(GTK_OBJECT(button), "clicked",
                     GTK_SIGNAL_FUNC(list_delete), structname);
  gtk_box_pack_start(GTK_BOX(hbbox), button, TRUE, TRUE, 0);

  button = gtk_button_new_with_label(_("Up"));
  gtk_widget_set_sensitive(button, FALSE);
  gtk_object_set_data(GTK_OBJECT(button), "clist", clist);
  gtk_object_set_data(GTK_OBJECT(clist), "up", button);
  gtk_signal_connect(GTK_OBJECT(button), "clicked",
                     GTK_SIGNAL_FUNC(list_up), structname);
  gtk_box_pack_start(GTK_BOX(hbbox), button, TRUE, TRUE, 0);

  button = gtk_button_new_with_label(_("Down"));
  gtk_widget_set_sensitive(button, FALSE);
  gtk_object_set_data(GTK_OBJECT(button), "clist", clist);
  gtk_object_set_data(GTK_OBJECT(clist), "down", button);
  gtk_signal_connect(GTK_OBJECT(button), "clicked",
                     GTK_SIGNAL_FUNC(list_down), structname);
  gtk_box_pack_start(GTK_BOX(hbbox), button, TRUE, TRUE, 0);

  gtk_box_pack_start(GTK_BOX(vbox), hbbox, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(hbox), vbox, FALSE, FALSE, 0);

  table = gtk_table_new(nummembers + 1, 2, FALSE);
  gtk_table_set_row_spacings(GTK_TABLE(table), 5);
  gtk_table_set_col_spacings(GTK_TABLE(table), 5);

  AddStructConfig(table, 0, structname, &namemember);
  for (i = 0; i < nummembers; i++) {
    AddStructConfig(table, i + 1, structname, &members[i]);
  }

  gtk_box_pack_start(GTK_BOX(hbox), table, TRUE, TRUE, 0);

  return hbox;
}

static void FillSoundsList(GtkCList *clist)
{
  gchar *rowtext[2];
  gint i, row;

  gtk_clist_freeze(clist);
  gtk_clist_clear(clist);
  for (i = 0; i < NUMGLOB; i++) {
    if (strlen(Globals[i].Name) > 7
	&& strncmp(Globals[i].Name, "Sounds.", 7) == 0) {
      rowtext[0] = &Globals[i].Name[7];
      rowtext[1] = _(Globals[i].Help);
      row = gtk_clist_append(clist, rowtext);
      gtk_clist_set_row_data(clist, row, GINT_TO_POINTER(i));
    }
  }

  gtk_clist_thaw(clist);
}

void OptDialog(GtkWidget *widget, gpointer data)
{
  GtkWidget *dialog, *notebook, *table, *label, *check, *entry;
  GtkWidget *hbox, *vbox, *vbox2, *hsep, *button, *hbbox, *clist;
  GtkWidget *scrollwin;
  GtkAccelGroup *accel_group;
  gchar *sound_titles[2];
  int width;

  struct ConfigMembers locmembers[] = {
    { N_("Police presence"), "PolicePresence" },
    { N_("Minimum no. of drugs"), "MinDrug" },
    { N_("Maximum no. of drugs"), "MaxDrug" },
    { NULL, NULL }
  };
  struct ConfigMembers drugmembers[] = {
    { N_("Minimum normal price"), "MinPrice" },
    { N_("Maximum normal price"), "MaxPrice" },
    { N_("Can be specially cheap"), "Cheap" },
    { N_("Cheap string"), "CheapStr" },
    { N_("Can be specially expensive"), "Expensive" },
    { NULL, NULL }
  };
  struct ConfigMembers gunmembers[] = {
    { N_("Price"), "Price" },
    { N_("Inventory space"), "Space" },
    { N_("Damage"), "Damage" },
    { NULL, NULL }
  };
  struct ConfigMembers copmembers[] = {
    { N_("Name of one deputy"), "DeputyName" },
    { N_("Name of several deputies"), "DeputiesName" },
    { N_("Minimum no. of deputies"), "MinDeputies" },
    { N_("Maximum no. of deputies"), "MaxDeputies" },
    { N_("Cop armour"), "Armour" },
    { N_("Deputy armour"), "DeputyArmour" },
    { NULL, NULL }
  };

  dialog = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  accel_group = gtk_accel_group_new();
  gtk_window_add_accel_group(GTK_WINDOW(dialog), accel_group);

  gtk_window_set_title(GTK_WINDOW(dialog), _("Options"));
  my_set_dialog_position(GTK_WINDOW(dialog));
  gtk_container_set_border_width(GTK_CONTAINER(dialog), 7);
  gtk_window_set_modal(GTK_WINDOW(dialog), TRUE);

  gtk_window_set_transient_for(GTK_WINDOW(dialog),
                               GTK_WINDOW(MainWindow));

  vbox = gtk_vbox_new(FALSE, 7);

  notebook = gtk_notebook_new();

  table = gtk_table_new(8, 3, FALSE);
  gtk_table_set_row_spacings(GTK_TABLE(table), 5);
  gtk_table_set_col_spacings(GTK_TABLE(table), 5);

  check = NewConfigCheck("Sanitized", _("Remove drug references"));
  gtk_table_attach_defaults(GTK_TABLE(table), check, 0, 1, 0, 1);

#ifdef HAVE_GLIB2
  check = gtk_check_button_new_with_label(_("Unicode config file"));
  gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(check), IsConfigFileUTF8());
  gtk_table_attach_defaults(GTK_TABLE(table), check, 1, 3, 0, 1);
  gtk_object_set_data(GTK_OBJECT(dialog), "unicode_check", check);
#endif

  label = gtk_label_new(_("Game length (turns)"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 1, 2,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("NumTurns");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 3, 1, 2);

  label = gtk_label_new(_("Starting cash"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 2, 3,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("StartCash");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 3, 2, 3);

  label = gtk_label_new(_("Starting debt"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 3, 4,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("StartDebt");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 3, 3, 4);

  label = gtk_label_new(_("Currency symbol"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 4, 5,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("Currency.Symbol");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 2, 4, 5);
  check = NewConfigCheck("Currency.Prefix", _("Symbol prefixes prices"));
  gtk_table_attach_defaults(GTK_TABLE(table), check, 2, 3, 4, 5);

  label = gtk_label_new(_("Name of one bitch"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 5, 6,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("Names.Bitch");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 3, 5, 6);

  label = gtk_label_new(_("Name of several bitches"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 6, 7,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("Names.Bitches");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 3, 6, 7);

#ifndef CYGWIN
  label = gtk_label_new(_("Web browser"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 7, 8,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("WebBrowser");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 3, 7, 8);
#endif

  gtk_container_set_border_width(GTK_CONTAINER(table), 7);
  label = gtk_label_new(_("General"));
  gtk_notebook_append_page(GTK_NOTEBOOK(notebook), table, label);

  hbox = CreateList("Location", locmembers);
  gtk_container_set_border_width(GTK_CONTAINER(hbox), 7);

  label = gtk_label_new(_("Locations"));
  gtk_notebook_append_page(GTK_NOTEBOOK(notebook), hbox, label);

  vbox2 = gtk_vbox_new(FALSE, 8);
  gtk_container_set_border_width(GTK_CONTAINER(vbox2), 7);

  hbox = CreateList("Drug", drugmembers);
  gtk_box_pack_start(GTK_BOX(vbox2), hbox, TRUE, TRUE, 0);

  hsep = gtk_hseparator_new();
  gtk_box_pack_start(GTK_BOX(vbox2), hsep, FALSE, FALSE, 0);

  table = gtk_table_new(2, 2, FALSE);
  gtk_table_set_row_spacings(GTK_TABLE(table), 5);
  gtk_table_set_col_spacings(GTK_TABLE(table), 5);
  label = gtk_label_new(_("Expensive string 1"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 0, 1,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("Drugs.ExpensiveStr1");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 2, 0, 1);

  label = gtk_label_new(_("Expensive string 2"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 1, 2,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("Drugs.ExpensiveStr2");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 2, 1, 2);
  gtk_box_pack_start(GTK_BOX(vbox2), table, FALSE, FALSE, 0);

  label = gtk_label_new(_("Drugs"));
  gtk_notebook_append_page(GTK_NOTEBOOK(notebook), vbox2, label);

  hbox = CreateList("Gun", gunmembers);
  gtk_container_set_border_width(GTK_CONTAINER(hbox), 7);
  label = gtk_label_new(_("Guns"));
  gtk_notebook_append_page(GTK_NOTEBOOK(notebook), hbox, label);

  hbox = CreateList("Cop", copmembers);
  gtk_container_set_border_width(GTK_CONTAINER(hbox), 7);
  label = gtk_label_new(_("Cops"));
  gtk_notebook_append_page(GTK_NOTEBOOK(notebook), hbox, label);

  table = gtk_table_new(6, 4, FALSE);
  gtk_table_set_row_spacings(GTK_TABLE(table), 5);
  gtk_table_set_col_spacings(GTK_TABLE(table), 5);

  check = NewConfigCheck("MetaServer.Active",
                         _("Server reports to metaserver"));
  gtk_table_attach_defaults(GTK_TABLE(table), check, 0, 2, 0, 1);

#ifdef CYGWIN
  check = NewConfigCheck("MinToSysTray", _("Minimize to System Tray"));
  gtk_table_attach_defaults(GTK_TABLE(table), check, 2, 4, 0, 1);
#endif

  label = gtk_label_new(_("Metaserver hostname"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 1, 2,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("MetaServer.Name");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 2, 1, 2);

  label = gtk_label_new(_("Port"));
  gtk_table_attach(GTK_TABLE(table), label, 2, 3, 1, 2,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("MetaServer.Port");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 3, 4, 1, 2);

  label = gtk_label_new(_("Web proxy hostname"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 2, 3,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("MetaServer.ProxyName");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 2, 2, 3);

  label = gtk_label_new(_("Port"));
  gtk_table_attach(GTK_TABLE(table), label, 2, 3, 2, 3,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("MetaServer.ProxyPort");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 3, 4, 2, 3);

  label = gtk_label_new(_("Script path"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 3, 4,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("MetaServer.Path");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 4, 3, 4);

  label = gtk_label_new(_("Comment"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 4, 5,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("MetaServer.Comment");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 4, 4, 5);

  label = gtk_label_new(_("MOTD (welcome message)"));
  gtk_table_attach(GTK_TABLE(table), label, 0, 1, 5, 6,
                   GTK_SHRINK, GTK_SHRINK, 0, 0);
  entry = NewConfigEntry("ServerMOTD");
  gtk_table_attach_defaults(GTK_TABLE(table), entry, 1, 4, 5, 6);

  gtk_container_set_border_width(GTK_CONTAINER(table), 7);
  label = gtk_label_new(_("Server"));
  gtk_notebook_append_page(GTK_NOTEBOOK(notebook), table, label);

  vbox2 = gtk_vbox_new(FALSE, 5);
  gtk_container_set_border_width(GTK_CONTAINER(vbox2), 7);

  sound_titles[0] = _("Sound name");
  sound_titles[1] = _("Description");
  clist = gtk_scrolled_clist_new_with_titles(2, sound_titles, &scrollwin);
  gtk_clist_column_titles_passive(GTK_CLIST(clist));
  gtk_clist_set_selection_mode(GTK_CLIST(clist), GTK_SELECTION_SINGLE);
  FillSoundsList(GTK_CLIST(clist));
  gtk_signal_connect(GTK_OBJECT(clist), "select_row",
                     GTK_SIGNAL_FUNC(sound_row_select), NULL);
  gtk_signal_connect(GTK_OBJECT(clist), "unselect_row",
                     GTK_SIGNAL_FUNC(sound_row_unselect), NULL);

  clists = g_slist_append(clists, clist);

  gtk_box_pack_start(GTK_BOX(vbox2), scrollwin, TRUE, TRUE, 0);

  hbox = gtk_hbox_new(FALSE, 5);
  label = gtk_label_new(_("Sound file"));
  gtk_box_pack_start(GTK_BOX(hbox), label, FALSE, FALSE, 0);

  entry = gtk_entry_new();
  gtk_object_set_data(GTK_OBJECT(clist), "entry", entry);
  gtk_box_pack_start(GTK_BOX(hbox), entry, TRUE, TRUE, 0);

  button = gtk_button_new_with_label(_("Browse..."));
  gtk_signal_connect_object(GTK_OBJECT(button), "clicked",
                            GTK_SIGNAL_FUNC(BrowseSound), GTK_OBJECT(entry));
  gtk_box_pack_start(GTK_BOX(hbox), button, FALSE, FALSE, 0);

  button = gtk_button_new_with_label(_("Play"));
  gtk_signal_connect_object(GTK_OBJECT(button), "clicked",
                            GTK_SIGNAL_FUNC(TestPlaySound), GTK_OBJECT(entry));
  gtk_box_pack_start(GTK_BOX(hbox), button, FALSE, FALSE, 0);

  gtk_box_pack_start(GTK_BOX(vbox2), hbox, FALSE, FALSE, 0);

  label = gtk_label_new(_("Sounds"));
  gtk_notebook_append_page(GTK_NOTEBOOK(notebook), vbox2, label);

  gtk_notebook_set_page(GTK_NOTEBOOK(notebook), 0);

  gtk_box_pack_start(GTK_BOX(vbox), notebook, TRUE, TRUE, 0);

  hsep = gtk_hseparator_new();
  gtk_box_pack_start(GTK_BOX(vbox), hsep, FALSE, FALSE, 0);

  hbbox = my_hbbox_new();

  button = NewStockButton(GTK_STOCK_OK, accel_group);
  gtk_signal_connect(GTK_OBJECT(button), "clicked",
                     GTK_SIGNAL_FUNC(OKCallback), (gpointer)dialog);
  gtk_box_pack_start_defaults(GTK_BOX(hbbox), button);

  button = NewStockButton(GTK_STOCK_HELP, accel_group);
  gtk_signal_connect(GTK_OBJECT(button), "clicked",
                     GTK_SIGNAL_FUNC(HelpCallback), (gpointer)notebook);
  gtk_box_pack_start_defaults(GTK_BOX(hbbox), button);

  button = NewStockButton(GTK_STOCK_CANCEL, accel_group);
  gtk_signal_connect_object(GTK_OBJECT(button), "clicked",
                            GTK_SIGNAL_FUNC(gtk_widget_destroy),
                            GTK_OBJECT(dialog));
  gtk_signal_connect(GTK_OBJECT(dialog), "destroy",
                     GTK_SIGNAL_FUNC(FinishOptDialog), NULL);
  gtk_box_pack_start_defaults(GTK_BOX(hbbox), button);

  gtk_box_pack_start(GTK_BOX(vbox), hbbox, FALSE, FALSE, 0);

  gtk_container_add(GTK_CONTAINER(dialog), vbox);

  gtk_widget_show_all(dialog);

  width = gtk_clist_optimal_column_width(GTK_CLIST(clist), 0);
  gtk_clist_set_column_width(GTK_CLIST(clist), 0, width);
}
